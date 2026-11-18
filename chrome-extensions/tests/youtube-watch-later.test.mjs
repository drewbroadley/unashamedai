#!/usr/bin/env node
/*
 * Tests for youtube-clear-watch-later/innertube.js, the Watch Later API
 * helpers. The fixtures mirror the shape of the responses YouTube's
 * /youtubei/v1/browse and /youtubei/v1/browse/edit_playlist returned in
 * November 2026 (paths recorded from the live site, contents made up).
 *
 * Run:  node tests/youtube-watch-later.test.mjs
 */
import { readFileSync } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";
import { runInNewContext } from "node:vm";
import { createHash } from "node:crypto";

const ROOT = join(dirname(fileURLToPath(import.meta.url)), "..");
const src = readFileSync(join(ROOT, "youtube-clear-watch-later", "innertube.js"), "utf8");
const sandbox = { globalThis: null };
sandbox.globalThis = sandbox;
runInNewContext(src, sandbox);
const W = sandbox.YTWatchLater;

let failures = 0;
let passed = 0;
function ok(cond, name, detail = "") {
  if (cond) passed++;
  else {
    failures++;
    console.error(`  ✗ ${name}${detail ? `  — ${detail}` : ""}`);
  }
}
const eq = (a, b) => JSON.stringify(a) === JSON.stringify(b);
const sha1Hex = async (s) => createHash("sha1").update(s).digest("hex");

// ---- fixtures ---------------------------------------------------------------

const setId = (n) => n.toString(16).toUpperCase().padStart(16, "0");
const vid = (n) => `vid${String(n).padStart(8, "0")}`;
const item = (n, title = `Video ${n}`) => ({
  playlistVideoRenderer: {
    videoId: vid(n),
    setVideoId: setId(n),
    title: { runs: [{ text: title }] },
    // the menu repeats the setVideoId inside its own endpoints; must not double-count
    menu: {
      menuRenderer: {
        items: [
          {
            menuServiceItemRenderer: {
              serviceEndpoint: {
                playlistEditEndpoint: { playlistId: "WL", actions: [{ setVideoId: setId(n), action: "ACTION_REMOVE_VIDEO" }] },
              },
            },
          },
        ],
      },
    },
  },
});
const contItem = (token) => ({
  continuationItemRenderer: {
    continuationEndpoint: { continuationCommand: { token, request: "CONTINUATION_REQUEST_TYPE_BROWSE" } },
  },
});
const tracking = (li) => ({
  responseContext: {
    serviceTrackingParams: [
      { service: "GFEEDBACK", params: [{ key: "logged_in", value: li }] },
      { service: "CSI", params: [{ key: "yt_li", value: li }] },
    ],
  },
});
const firstPage = (ns, token, total) => ({
  ...tracking("1"),
  header: { playlistHeaderRenderer: { playlistId: "WL", numVideosText: { runs: [{ text: total.toLocaleString("en-US") }, { text: " videos" }] } } },
  contents: {
    twoColumnBrowseResultsRenderer: {
      tabs: [
        {
          tabRenderer: {
            content: {
              sectionListRenderer: {
                contents: [
                  {
                    itemSectionRenderer: {
                      contents: [{ playlistVideoListRenderer: { contents: ns.map((n) => item(n)).concat(token ? [contItem(token)] : []) } }],
                    },
                  },
                ],
              },
            },
          },
        },
      ],
    },
  },
});
const nextPage = (ns, token) => ({
  ...tracking("1"),
  onResponseReceivedActions: [
    { appendContinuationItemsAction: { continuationItems: ns.map((n) => item(n)).concat(token ? [contItem(token)] : []) } },
  ],
});
const range = (a, b) => Array.from({ length: b - a }, (_, i) => a + i);

// ---- parseYtcfg -------------------------------------------------------------

{
  const cfgObj = {
    CLIENT_CANARY_STATE: "none",
    LOGGED_IN: true,
    SESSION_INDEX: 0,
    INNERTUBE_CONTEXT_CLIENT_NAME: 1,
    INNERTUBE_CONTEXT: { client: { clientName: "WEB", clientVersion: "2.20261118.01.00", note: "has } and { and \" inside" } },
  };
  const script = `(function(){window.foo=1;})();ytcfg.set({"CSI_SERVICE_NAME": 'youtube'});ytcfg.set(${JSON.stringify(cfgObj)});window.ytcfg.set('X', 1);`;
  const cfg = W.parseYtcfg(["var a = 1;", script]);
  ok(cfg && cfg.clientVersion === "2.20261118.01.00", "parseYtcfg reads client version");
  ok(cfg && cfg.clientName === "1", "parseYtcfg reads client name as a string");
  ok(cfg && cfg.sessionIndex === "0", "parseYtcfg reads session index 0 as '0'");
  ok(cfg && cfg.loggedIn === true, "parseYtcfg reads LOGGED_IN");
  ok(cfg && cfg.delegatedSessionId === "", "parseYtcfg: no delegated session → empty");
  ok(cfg && cfg.context.client.note.includes("}"), "parseYtcfg survives braces inside strings");
  ok(W.parseYtcfg(["ytcfg.set({'a': 1})"]) === null, "parseYtcfg returns null without INNERTUBE_CONTEXT");
  const brand = W.parseYtcfg([`ytcfg.set(${JSON.stringify({ ...cfgObj, DELEGATED_SESSION_ID: "1234", LOGGED_IN: false })})`]);
  ok(brand.delegatedSessionId === "1234" && brand.loggedIn === false, "parseYtcfg reads brand-account session and logged-out flag");
}

// ---- cookies and the auth header -----------------------------------------------

{
  const jar = "PREF=f6=40000000; SAPISID=abc/DEF; __Secure-1PAPISID=one; __Secure-3PAPISID=three; SID=zzz";
  ok(W.readCookie(jar, "SAPISID") === "abc/DEF", "readCookie finds SAPISID");
  ok(W.readCookie(jar, "APISID") === "", "readCookie does not match a suffix (APISID ≠ SAPISID)");
  ok(W.readCookie("", "SAPISID") === "", "readCookie on empty jar");

  const ts = 1795000000;
  const origin = "https://www.youtube.com";
  const h = await W.authHeader(jar, origin, ts, sha1Hex);
  const expect = (v) => createHash("sha1").update(`${ts} ${v} ${origin}`).digest("hex");
  ok(
    h === `SAPISIDHASH ${ts}_${expect("abc/DEF")} SAPISID1PHASH ${ts}_${expect("one")} SAPISID3PHASH ${ts}_${expect("three")}`,
    "authHeader matches YouTube's SAPISIDHASH format",
    h
  );
  ok((await W.authHeader("SID=zzz", origin, ts, sha1Hex)) === "", "authHeader empty when signed out");
  const only = await W.authHeader("SAPISID=x", origin, ts, sha1Hex);
  ok(only.startsWith("SAPISIDHASH ") && !only.includes("1PHASH"), "authHeader with only SAPISID");
}

// ---- extractPage ----------------------------------------------------------------

{
  const p1 = W.extractPage(firstPage(range(1, 101), "TOKEN-2", 4681));
  ok(p1.items.length === 100, "first page: 100 entries (menu setVideoIds not double-counted)", p1.items.length);
  ok(p1.items[0].setVideoId === setId(1) && p1.items[0].videoId === vid(1), "first page: ids");
  ok(p1.items[0].title === "Video 1", "first page: title from runs");
  ok(p1.continuation === "TOKEN-2", "first page: continuation token");
  ok(p1.total === 4681, "first page: header count with thousands separator", p1.total);

  const p2 = W.extractPage(nextPage(range(101, 201), "TOKEN-3"));
  ok(p2.items.length === 100 && p2.items[0].setVideoId === setId(101), "continuation page: entries");
  ok(p2.continuation === "TOKEN-3" && p2.total === null, "continuation page: token, no header");

  const last = W.extractPage(nextPage(range(201, 230), null));
  ok(last.items.length === 29 && last.continuation === "", "last page: no continuation");

  const bad = nextPage([1], null);
  bad.onResponseReceivedActions[0].appendContinuationItemsAction.continuationItems.push({
    playlistVideoRenderer: { videoId: "x", setVideoId: "not-hex<script>" },
  });
  ok(W.extractPage(bad).items.length === 1, "extractPage ignores malformed setVideoIds");
  ok(eq(W.extractPage({}).items, []) && W.extractPage(null).continuation === "", "extractPage on empty input");

  ok(W.headerCount({ metadataParts: [{ text: { content: "1 video" } }] }) === 1, "headerCount: newer metadataParts layout");
  ok(W.headerCount({ numVideosText: { runs: [{ text: "No videos" }] } }) === null, "headerCount: 'No videos' → null");
}

// ---- logged-out / success detection ---------------------------------------------

{
  ok(W.isLoggedOut(tracking("0")) === true, "isLoggedOut: logged_in 0");
  ok(W.isLoggedOut(tracking("1")) === false, "isLoggedOut: logged_in 1");
  ok(W.isLoggedOut({}) === false, "isLoggedOut: no tracking params");
  ok(W.editSucceeded({ status: "STATUS_SUCCEEDED" }) === true, "editSucceeded");
  ok(W.editSucceeded({ status: "STATUS_FAILED" }) === false && W.editSucceeded(null) === false, "editSucceeded: failure");
}

// ---- request bodies and chunking -------------------------------------------------

{
  const body = W.removeBody({ client: { clientName: "WEB" } }, [setId(1), setId(2)]);
  ok(body.playlistId === "WL", "removeBody targets WL");
  ok(
    eq(body.actions, [
      { action: "ACTION_REMOVE_VIDEO", setVideoId: setId(1) },
      { action: "ACTION_REMOVE_VIDEO", setVideoId: setId(2) },
    ]),
    "removeBody: one ACTION_REMOVE_VIDEO per entry"
  );
  ok(eq(W.chunk(range(0, 1201), 500).map((c) => c.length), [500, 500, 201]), "chunk(1201, 500)");
  ok(eq(W.chunk([], 500), []), "chunk([])");
}

// ---- createClient against a fake fetch -------------------------------------------

function fakeFetch(handler) {
  const calls = [];
  const fn = async (url, init) => {
    const body = JSON.parse(init.body);
    calls.push({ url, init, body });
    const [status, json] = handler(url, body, calls.length);
    return { status, json: async () => json };
  };
  fn.calls = calls;
  return fn;
}
const CFG = {
  context: { client: { clientName: "WEB", clientVersion: "2.20261118.01.00" } },
  clientName: "1",
  clientVersion: "2.20261118.01.00",
  sessionIndex: "0",
  delegatedSessionId: "",
  loggedIn: true,
};
const client = (fetch, cookies = "SAPISID=abc", cfg = CFG) =>
  W.createClient({ cfg, origin: "https://www.youtube.com", fetch, getCookies: () => cookies, sha1Hex, now: () => 1795000000000 });

{
  const f = fakeFetch((url, body) =>
    body.continuation ? [200, nextPage(range(101, 150), null)] : [200, firstPage(range(1, 101), "T2", 149)]
  );
  const c = client(f);
  const p1 = await c.firstPage();
  const p2 = await c.nextPage(p1.continuation);
  ok(p1.items.length === 100 && p2.items.length === 49 && p1.total === 149, "client pages through the playlist");
  const [first, second] = f.calls;
  ok(first.url === "https://www.youtube.com/youtubei/v1/browse?prettyPrint=false", "client: browse URL is same-origin", first.url);
  ok(first.body.browseId === "VLWL" && first.body.params === W.SHOW_UNAVAILABLE_PARAMS, "client: first page asks for unavailable videos too");
  ok(second.body.continuation === "T2" && !second.body.browseId, "client: continuation request");
  const h = first.init.headers;
  ok(/^SAPISIDHASH 1795000000_[0-9a-f]{40}$/.test(h.Authorization), "client: signs requests", h.Authorization);
  ok(h["X-Origin"] === "https://www.youtube.com" && h["X-Goog-AuthUser"] === "0", "client: origin + auth user headers");
  ok(!("X-Goog-PageId" in h), "client: no page id for a personal account");
  ok(first.init.credentials === "same-origin" && first.init.method === "POST", "client: same-origin POST");
}

{
  const f = fakeFetch(() => [200, { ...tracking("1"), status: "STATUS_SUCCEEDED" }]);
  await client(f).removeEntries([setId(1), "bogus", setId(2)]);
  const call = f.calls[0];
  ok(call.url.endsWith("/youtubei/v1/browse/edit_playlist?prettyPrint=false"), "removeEntries: edit_playlist URL");
  ok(call.body.actions.length === 2, "removeEntries: drops malformed ids before sending");
  const none = fakeFetch(() => [200, {}]);
  await client(none).removeEntries(["bogus"]);
  ok(none.calls.length === 0, "removeEntries: nothing valid → no request");
}

{
  const brandCfg = { ...CFG, delegatedSessionId: "1234", sessionIndex: "2" };
  const f = fakeFetch(() => [200, { ...tracking("1"), status: "STATUS_SUCCEEDED" }]);
  await client(f, "SAPISID=abc", brandCfg).removeEntries([setId(1)]);
  ok(f.calls[0].init.headers["X-Goog-PageId"] === "1234" && f.calls[0].init.headers["X-Goog-AuthUser"] === "2", "client: brand account headers");
}

async function kindOf(handler, cookies) {
  try {
    await client(fakeFetch(handler), cookies).removeEntries([setId(1)]);
    return "no error";
  } catch (e) {
    return e.kind;
  }
}
ok((await kindOf(() => [200, { status: "STATUS_SUCCEEDED" }], "SID=only")) === "logged-out", "client: no SAPISID → logged-out, no request");
ok((await kindOf(() => [200, { ...tracking("0") }])) === "logged-out", "client: 200 but logged_in 0 → logged-out");
ok((await kindOf(() => [429, {}])) === "rate-limited", "client: 429 → rate-limited");
ok((await kindOf(() => [503, {}])) === "server", "client: 5xx → server");
ok((await kindOf(() => [400, { error: { code: 400 } }])) === "bad-request", "client: 400 → bad-request");
ok((await kindOf(() => [401, {}])) === "logged-out", "client: 401 → logged-out");
ok((await kindOf(() => [200, { ...tracking("1"), status: "STATUS_FAILED" }])) === "bad-request", "client: unconfirmed edit → bad-request");
ok(
  (await kindOf(() => {
    throw new Error("offline");
  })) === "network",
  "client: fetch throws → network"
);

console.log(`\nyoutube-watch-later: ${passed} passed, ${failures} failed`);
if (failures) process.exit(1);
