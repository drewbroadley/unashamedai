/*
 * YouTube: Clear Watch Later — the worker that runs inside a YouTube tab.
 * --------------------------------------------------------------------------
 * Does nothing until the popup asks. When asked to clear, it:
 *   1. lists every entry in Watch Later (100 per request, like the page does),
 *   2. removes them oldest-added first, up to 500 per request,
 *   3. re-checks the playlist and makes one more pass if anything is left,
 *   4. reloads the tab if you're looking at the Watch Later page.
 *
 * Requests go to www.youtube.com only — the same origin this script runs on —
 * using the same API calls YouTube's own "Remove from Watch later" menu makes.
 * See innertube.js for the request details and README.md for why.
 */
(function () {
  "use strict";

  const W = globalThis.YTWatchLater;
  const ORIGIN = "https://www.youtube.com";
  if (location.origin !== ORIGIN || !W) return;

  const BATCH_SIZE = 500; // proven against the live API; larger is untested
  const PAUSE_MS = 300; // breathing room between requests
  const MAX_RETRIES = 4; // for rate limits / server errors, with backoff
  const MAX_PASSES = 3;
  const MAX_PAGES = 120; // Watch Later caps out at 5,000 videos = 50 pages
  const REMOVED_LOG_CAP = 6000;

  let job = idle();

  function idle() {
    return { running: false, phase: "idle", listed: 0, removed: 0, failed: 0, total: null, error: "", stop: false, startedAt: 0, endedAt: 0 };
  }

  function publicState() {
    const { stop, ...rest } = job;
    return { ...rest, stopping: job.running && stop };
  }

  function broadcast() {
    try {
      chrome.runtime.sendMessage({ type: "ytwl-progress", state: publicState() }, () => void chrome.runtime.lastError);
    } catch {
      // popup closed or extension reloaded; the next status request catches up
    }
  }

  const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

  async function sha1Hex(s) {
    const buf = await crypto.subtle.digest("SHA-1", new TextEncoder().encode(s));
    return [...new Uint8Array(buf)].map((b) => b.toString(16).padStart(2, "0")).join("");
  }

  function makeClient() {
    const cfg = W.parseYtcfg([...document.scripts].map((s) => s.textContent || ""));
    if (!cfg) throw new W.ApiError("Couldn't read YouTube's page settings. Reload the tab and try again.", 0, "bad-request");
    if (!cfg.loggedIn) throw new W.ApiError("Sign in to YouTube in this tab first.", 0, "logged-out");
    return W.createClient({
      cfg,
      origin: ORIGIN,
      fetch: (url, init) => fetch(url, init),
      getCookies: () => document.cookie, // read per request, never stored
      sha1Hex,
      now: () => Date.now(),
    });
  }

  /** Run `fn`, retrying transient failures with exponential backoff. */
  async function withRetry(fn) {
    for (let attempt = 0; ; attempt++) {
      try {
        return await fn();
      } catch (e) {
        const transient = e && (e.kind === "rate-limited" || e.kind === "server" || e.kind === "network");
        if (!transient || attempt >= MAX_RETRIES || job.stop) throw e;
        await sleep(2000 * 2 ** attempt);
      }
    }
  }

  async function listAll(client) {
    const entries = [];
    let page = await withRetry(() => client.firstPage());
    if (page.total != null) job.total = page.total;
    entries.push(...page.items);
    job.listed = entries.length;
    broadcast();
    for (let n = 1; page.continuation && n < MAX_PAGES && !job.stop; n++) {
      await sleep(PAUSE_MS);
      const token = page.continuation;
      page = await withRetry(() => client.nextPage(token));
      entries.push(...page.items);
      job.listed = entries.length;
      broadcast();
    }
    const seen = new Set();
    return entries.filter((e) => !seen.has(e.setVideoId) && seen.add(e.setVideoId));
  }

  /**
   * Remove a batch. If YouTube rejects it as a bad request (usually one stale
   * entry), split it in half and try each half, down to single entries; a
   * single entry that still fails is skipped and counted.
   */
  async function removeBatch(client, batch, log) {
    if (job.stop || !batch.length) return;
    try {
      await withRetry(() => client.removeEntries(batch.map((e) => e.setVideoId)));
      job.removed += batch.length;
      for (const e of batch) log.push({ v: e.videoId, t: e.title });
    } catch (e) {
      if (e.kind !== "bad-request") throw e;
      if (batch.length === 1) {
        job.failed += 1;
        return;
      }
      const mid = Math.ceil(batch.length / 2);
      await removeBatch(client, batch.slice(0, mid), log);
      await sleep(PAUSE_MS);
      await removeBatch(client, batch.slice(mid), log);
      return;
    }
    broadcast();
  }

  /**
   * Keep a running list of everything removed (video id + title) so it can be
   * downloaded from the popup. Runs add to it, so stopping and resuming later
   * doesn't lose the first part; "Forget list" in the popup resets it.
   */
  async function loadLog() {
    try {
      const { removedLog } = await chrome.storage.local.get("removedLog");
      if (removedLog && Array.isArray(removedLog.items)) return removedLog;
    } catch {
      // unavailable; start a fresh list
    }
    return null;
  }

  async function saveLog(base, log) {
    if (!log.length) return; // never overwrite an earlier list with nothing
    const items = (base ? base.items : []).concat(log).slice(-REMOVED_LOG_CAP);
    try {
      await chrome.storage.local.set({
        removedLog: { since: base ? base.since : job.startedAt, updated: Date.now(), items },
      });
    } catch {
      // storage full or unavailable; the clear itself still happened
    }
  }

  async function clearAll() {
    job = idle();
    job.running = true;
    job.startedAt = Date.now();
    job.phase = "listing";
    broadcast();
    const log = [];
    const base = await loadLog();
    try {
      const client = makeClient();
      for (let pass = 0; pass < MAX_PASSES && !job.stop; pass++) {
        job.phase = "listing";
        broadcast();
        const entries = (await listAll(client)).reverse(); // oldest-added first
        if (!entries.length || job.stop) break;
        if (pass === 0 && job.total == null) job.total = entries.length;
        job.phase = "removing";
        broadcast();
        const before = job.removed;
        for (const batch of W.chunk(entries, BATCH_SIZE)) {
          if (job.stop) break;
          await removeBatch(client, batch, log);
          await saveLog(base, log);
          await sleep(PAUSE_MS);
        }
        if (job.removed === before) break; // nothing removable left
      }
      job.phase = job.stop ? "stopped" : "done";
    } catch (e) {
      job.phase = "error";
      job.error = (e && e.message) || String(e);
    } finally {
      job.running = false;
      job.endedAt = Date.now();
      await saveLog(base, log);
      broadcast();
    }
    if (job.removed > 0 && /^\/playlist$/.test(location.pathname) && new URLSearchParams(location.search).get("list") === W.PLAYLIST_ID) {
      setTimeout(() => location.reload(), 1500);
    }
  }

  async function count() {
    const client = makeClient();
    const page = await withRetry(() => client.firstPage());
    return page.total != null ? page.total : page.items.length + (page.continuation ? "+" : "");
  }

  chrome.runtime.onMessage.addListener((msg, sender, sendResponse) => {
    if (sender.id !== chrome.runtime.id) return; // only our own popup
    switch (msg && msg.type) {
      case "ytwl-status":
        sendResponse({ ok: true, state: publicState() });
        return;
      case "ytwl-count":
        if (job.running) {
          sendResponse({ ok: true, count: job.total, state: publicState() });
          return;
        }
        count().then(
          (n) => sendResponse({ ok: true, count: n, state: publicState() }),
          (e) => sendResponse({ ok: false, error: (e && e.message) || String(e), state: publicState() })
        );
        return true; // async response
      case "ytwl-start":
        if (!job.running) clearAll();
        sendResponse({ ok: true, state: publicState() });
        return;
      case "ytwl-stop":
        if (job.running) job.stop = true;
        sendResponse({ ok: true, state: publicState() });
        broadcast();
        return;
      default:
        return; // ignore anything else
    }
  });
})();
