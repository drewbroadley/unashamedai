/*
 * Reddit: Hide Promoted & Keep Rising
 * --------------------------------------------------------------------------
 * Two jobs on the Reddit ("shreddit") home feed:
 *
 *   1. Remove Promoted / Sponsored ads. Reddit renders every feed ad as a
 *      <shreddit-ad-post> element (a direct child of <shreddit-feed>, with a
 *      `promoted` attribute), separated from real posts by <hr> rules. Organic
 *      posts are <article> wrappers around <shreddit-post>. So we simply hide
 *      each <shreddit-ad-post> (and its trailing <hr> so no double divider).
 *
 *   2. Keep the feed sorted by Rising. The home feed defaults to "Best"; the
 *      Rising sort lives at the stable URL /rising/. So whenever you land on or
 *      navigate back to the default home feed we redirect it to /rising/.
 *
 *   3. Hide likely bots. Every post (<shreddit-post>) and comment
 *      (<shreddit-comment>) carries an `author` attribute. For each author we
 *      look up their public profile (/user/<name>/about.json, plus
 *      /overview.json when that alone isn't conclusive), score it with
 *      botcheck.js, and hide their posts and comments when the score reaches
 *      the user's threshold. Requests go only to www.reddit.com, one at a
 *      time and spaced out, and the results are cached for a day.
 */
(() => {
  "use strict";

  const HIDDEN_CLASS = "rrf-hidden";

  const DEFAULTS = {
    enabled: true,
    hidePromoted: true, // <shreddit-ad-post> ads
    sortRising: true, // redirect the default home feed to /rising/
    dim: false,
    hideBots: true, // hide posts/comments from accounts that look like bots
    botsInFeed: true,
    botsInComments: true,
    botDeepCheck: true, // also read recent activity (overview.json)
    botMinAgeDays: 30,
    botMinKarma: 20,
    botScoreThreshold: 3,
    botAllowlist: [], // lowercase usernames the user marked "not a bot"
  };

  let settings = { ...DEFAULTS };
  let pageHiddenCount = 0;

  function hide(el) {
    if (!el || el.classList.contains(HIDDEN_CLASS)) return;
    el.classList.add(HIDDEN_CLASS);
    pageHiddenCount++;
  }

  function sweep() {
    if (!settings.enabled) return;
    sweepBots();
    if (!settings.hidePromoted) return pushCount();
    // Ad posts (and a defensive fallback for any promoted <shreddit-post>).
    document
      .querySelectorAll("shreddit-ad-post, shreddit-post[promoted]")
      .forEach((ad) => {
        hide(ad);
        // Drop the trailing separator so we don't leave a double divider.
        const next = ad.nextElementSibling;
        if (next && next.tagName === "HR") hide(next);
      });
    pushCount();
  }

  function setActiveState() {
    const root = document.documentElement;
    root.classList.toggle("rrf-active", settings.enabled);
    root.classList.toggle("rrf-dim", settings.enabled && settings.dim);
    if (settings.enabled) sweep();
  }

  // ---- Likely-bot detection -------------------------------------------------
  const BC = globalThis.RedditBotCheck;
  const BOT_CLASS = "rrf-bot";
  const CACHE_PREFIX = "bc:";
  const CACHE_TTL_MS = 24 * 60 * 60 * 1000;
  const CACHE_MAX = 5000;
  const REQUEST_GAP_MS = 1500; // at most ~40 profile requests a minute
  const COMMENT_SLOTS = new Set(["commentAvatar", "commentMeta", "comment", "actionRow"]);

  // lowercase name -> { f, at } (features + fetch time) or { error: true }
  const known = new Map();
  const queued = new Set();
  const queue = []; // { name, key, stage: "about" | "activity" }
  let cacheLoaded = false;
  let settingsLoaded = false; // don't fetch anything until we know it's wanted
  let pumping = false;
  let nextRequestAt = 0;
  let pausedUntil = 0;

  let botItemsHidden = new WeakSet();
  let botHiddenCount = 0;
  let flaggedOnPage = new Map(); // key -> { name, score, reasons }

  function botsActive() {
    return settings.enabled && settings.hideBots && !!BC && cacheLoaded && settingsLoaded;
  }

  function thresholds() {
    return {
      botMinAgeDays: Number(settings.botMinAgeDays),
      botMinKarma: Number(settings.botMinKarma),
      botScoreThreshold: Number(settings.botScoreThreshold),
    };
  }

  function hideBot(item, parts) {
    for (const p of parts) p.classList.add(HIDDEN_CLASS, BOT_CLASS);
    if (!botItemsHidden.has(item)) {
      botItemsHidden.add(item);
      botHiddenCount++;
    }
  }

  function resetBotState() {
    botItemsHidden = new WeakSet();
    botHiddenCount = 0;
    flaggedOnPage = new Map();
  }

  function enqueue(name, key, stage, front) {
    if (stage === "about") {
      if (queued.has(key)) return;
      queued.add(key);
    }
    const job = { name, key, stage };
    if (front) queue.unshift(job);
    else queue.push(job);
    pump();
  }

  function verdictFor(name, key, memo) {
    if (memo.has(key)) return memo.get(key);
    let v = null;
    const entry = known.get(key);
    if ((settings.botAllowlist || []).includes(key)) v = null;
    else if (entry && entry.f) v = BC.score(entry.f, thresholds());
    else if (!entry && BC.isCheckableName(name)) enqueue(name, key, "about");
    memo.set(key, v);
    if (v && v.flagged) flaggedOnPage.set(key, { name, score: v.score, reasons: v.reasons });
    return v;
  }

  function sweepBots() {
    if (!botsActive()) return;
    const memo = new Map();
    const onPostPage = /\/comments\//.test(location.pathname);

    if (settings.botsInFeed) {
      document.querySelectorAll("shreddit-post[author]").forEach((post) => {
        // Don't blank out the post you deliberately opened; only listings.
        if (onPostPage && !post.closest("shreddit-feed")) return;
        const name = post.getAttribute("author");
        const v = verdictFor(name, String(name).toLowerCase(), memo);
        if (v && v.flagged) {
          const item = post.closest("article") || post;
          hideBot(item, [item]);
        }
      });
    }

    if (settings.botsInComments) {
      document.querySelectorAll("shreddit-comment[author]").forEach((c) => {
        const name = c.getAttribute("author");
        const v = verdictFor(name, String(name).toLowerCase(), memo);
        if (!v || !v.flagged) return;
        // Hide the bot's own avatar/header/body/actions but keep replies from
        // other people, which are nested inside the same element.
        const parts = [...c.children].filter((ch) => COMMENT_SLOTS.has(ch.getAttribute("slot")));
        hideBot(c, parts.length ? parts : [c]);
      });
    }
  }

  const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

  async function getJson(path) {
    // Same-origin request to the site you're already on: no host permission
    // needed, and Reddit sees it as an ordinary page request.
    const res = await fetch(path, {
      credentials: "same-origin",
      headers: { Accept: "application/json" },
    });
    if (res.status === 429) {
      const err = new Error("rate limited");
      err.retryAfter = Number(res.headers.get("retry-after")) || 60;
      throw err;
    }
    if (res.status === 404) return { status: 404, json: null };
    if (!res.ok) throw new Error("HTTP " + res.status);
    return { status: res.status, json: await res.json() };
  }

  function remember(key, f) {
    const entry = { f, at: Date.now() };
    known.set(key, entry);
    try {
      chrome.storage?.local?.set({ [CACHE_PREFIX + key]: entry });
    } catch (_) {
      /* context invalidated */
    }
  }

  async function runJob(job) {
    const base = "/user/" + encodeURIComponent(job.name);
    if (job.stage === "about") {
      const { status, json } = await getJson(base + "/about.json?raw_json=1");
      const f = BC.extractFeatures(json, status);
      if (!f.name) f.name = job.name;
      remember(job.key, f);
      if (settings.botDeepCheck && BC.needsActivityCheck(f, thresholds())) {
        enqueue(job.name, job.key, "activity", true);
      }
    } else {
      const { json } = await getJson(base + "/overview.json?limit=50&raw_json=1");
      const entry = known.get(job.key);
      if (!entry || !entry.f) return;
      remember(job.key, { ...entry.f, recent: BC.extractActivity(json) });
    }
    scheduleSweep();
  }

  async function pump() {
    if (pumping) return;
    pumping = true;
    try {
      while (queue.length && botsActive()) {
        const wait = Math.max(pausedUntil, nextRequestAt) - Date.now();
        if (wait > 0) await sleep(wait);
        const job = queue.shift();
        nextRequestAt = Date.now() + REQUEST_GAP_MS;
        try {
          await runJob(job);
        } catch (e) {
          if (e && e.retryAfter) {
            // Reddit asked us to slow down: back off and retry this one.
            pausedUntil = Date.now() + e.retryAfter * 1000;
            queue.unshift(job);
          } else if (job.stage === "about") {
            // Network error or private/blocked profile: don't guess, don't
            // retry this page view. Never treated as a bot signal.
            known.set(job.key, { error: true });
          }
        }
      }
    } finally {
      pumping = false;
    }
  }

  function loadCache() {
    const done = () => {
      cacheLoaded = true;
      scheduleSweep();
    };
    if (!chrome.storage?.local) return done();
    chrome.storage.local.get(null, (all) => {
      const now = Date.now();
      const stale = [];
      const fresh = [];
      for (const [k, v] of Object.entries(all || {})) {
        if (!k.startsWith(CACHE_PREFIX)) continue;
        if (!v || !v.f || now - v.at > CACHE_TTL_MS) stale.push(k);
        else fresh.push([k, v]);
      }
      // Keep the cache bounded: drop the oldest beyond CACHE_MAX.
      fresh.sort((a, b) => b[1].at - a[1].at);
      for (const [k] of fresh.splice(CACHE_MAX)) stale.push(k);
      for (const [k, v] of fresh) known.set(k.slice(CACHE_PREFIX.length), v);
      if (stale.length) chrome.storage.local.remove(stale);
      done();
    });
  }

  // ---- Keep the feed on Rising ----------------------------------------------
  // The default home feed ("/", "?feed=home", or "/best/") sorts by Best; the
  // Rising sort is the path /rising/. Redirect there when you land on or
  // navigate back to the default home feed.
  //
  // Loop guard: if Reddit sends us straight back to the home feed (a server
  // redirect, or its client router rewriting /rising/ to /), redirecting again
  // would reload forever. So a redirect is remembered for the tab session, and
  // landing back on home within BOUNCE_MS of one means Reddit is overriding
  // us: stop redirecting in this tab and leave the page alone. sessionStorage
  // holds only these two non-sensitive per-tab flags (see ../SECURITY.md).
  const RISING_LAST_KEY = "rrf-rising-last";
  const RISING_OFF_KEY = "rrf-rising-bounced";
  const BOUNCE_MS = 10000;

  function enforceRisingSort() {
    if (!settings.sortRising) return;
    const p = location.pathname;
    const isDefaultHome = p === "/" || p === "/best" || p === "/best/";
    if (!isDefaultHome) return; // leave /rising/, /hot/, /new/, /top/, /r/*, etc.
    try {
      if (sessionStorage.getItem(RISING_OFF_KEY)) return;
      const last = Number(sessionStorage.getItem(RISING_LAST_KEY)) || 0;
      if (Date.now() - last < BOUNCE_MS) {
        sessionStorage.setItem(RISING_OFF_KEY, "1");
        return;
      }
      sessionStorage.setItem(RISING_LAST_KEY, String(Date.now()));
    } catch (_) {
      return; // no sessionStorage means no loop guard, so don't redirect at all
    }
    location.replace(location.origin + "/rising/");
  }

  // ---- Count reporting ------------------------------------------------------
  function pushCount() {
    try {
      chrome.runtime?.sendMessage?.({
        type: "rrf-count",
        count: pageHiddenCount,
        botCount: botHiddenCount,
      });
    } catch (_) {
      /* popup closed / context invalidated */
    }
  }

  // ---- Debounced observer ---------------------------------------------------
  let pending = false;
  function scheduleSweep() {
    if (pending) return;
    pending = true;
    requestAnimationFrame(() => {
      pending = false;
      sweep();
    });
  }

  const observer = new MutationObserver(scheduleSweep);

  function startObserving() {
    if (!document.body) {
      requestAnimationFrame(startObserving);
      return;
    }
    observer.observe(document.body, { childList: true, subtree: true });
    setActiveState();
    sweep();
  }

  // ---- Settings + messaging -------------------------------------------------
  chrome.storage?.sync?.get(DEFAULTS, (stored) => {
    settings = { ...DEFAULTS, ...stored };
    settingsLoaded = true;
    enforceRisingSort(); // redirect before rendering the wrong sort, if needed
    setActiveState();
  });

  chrome.storage?.onChanged?.addListener((changes, area) => {
    if (area !== "sync") return;
    let touched = false;
    for (const key of Object.keys(DEFAULTS)) {
      if (changes[key]) {
        settings[key] = changes[key].newValue;
        touched = true;
      }
    }
    if (touched) {
      if (changes.sortRising && changes.sortRising.newValue) {
        // Switching the option back on is a fresh request: forget a bounce.
        try {
          sessionStorage.removeItem(RISING_OFF_KEY);
          sessionStorage.removeItem(RISING_LAST_KEY);
        } catch (_) {
          /* no sessionStorage */
        }
        enforceRisingSort();
      }
      pageHiddenCount = 0;
      resetBotState();
      document
        .querySelectorAll("." + HIDDEN_CLASS)
        .forEach((n) => n.classList.remove(HIDDEN_CLASS, BOT_CLASS));
      setActiveState();
      pump(); // resume lookups if bot hiding was just switched back on
    }
  });

  chrome.runtime?.onMessage?.addListener((msg, sender, sendResponse) => {
    // Only trust messages from our own extension pages (the popup).
    if (sender.id !== chrome.runtime.id) return;
    if (msg?.type === "rrf-get-count") {
      sendResponse({
        count: pageHiddenCount,
        botCount: botHiddenCount,
        bots: [...flaggedOnPage.values()],
        pending: queue.length,
      });
    }
    return true;
  });

  // Reddit is a single-page app: clicking "Home" navigates client-side without
  // reloading this script. Poll for path changes so we re-apply the Rising sort
  // (and reset the per-view count) whenever you land back on the home feed.
  let lastPath = location.pathname;
  setInterval(() => {
    if (location.pathname !== lastPath) {
      lastPath = location.pathname;
      pageHiddenCount = 0;
      resetBotState();
      enforceRisingSort();
    }
  }, 400);

  loadCache();
  startObserving();
})();
