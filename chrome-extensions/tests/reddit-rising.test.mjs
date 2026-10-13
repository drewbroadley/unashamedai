#!/usr/bin/env node
/*
 * Rising-redirect tests for reddit-remove-promoted-keep-rising.
 *
 * "Keep Rising" does a full-page location.replace("/rising/") when you land on
 * the default home feed. If Reddit sends /rising/ straight back to "/", an
 * unguarded redirect reloads the tab forever (versions up to 1.1.0 did). These
 * tests load the real content.js in a fake page and simulate that bounce, plus
 * the popup switches that must stop the redirect.
 *
 * Run:  node tests/reddit-rising.test.mjs
 */
import { readFileSync } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";
import { runInNewContext } from "node:vm";

const ROOT = join(dirname(fileURLToPath(import.meta.url)), "..");
const src = readFileSync(
  join(ROOT, "reddit-remove-promoted-keep-rising", "content.js"),
  "utf8"
);

const T0 = 1_790_000_000_000; // a realistic Date.now()

// A sessionStorage that survives "reloads" (it's per-tab in the browser).
function makeSessionStorage() {
  const m = new Map();
  return {
    getItem: (k) => (m.has(k) ? m.get(k) : null),
    setItem: (k, v) => m.set(k, String(v)),
    removeItem: (k) => m.delete(k),
  };
}

// Load content.js once, as a fresh page at `path`. Bot hiding stays inert:
// botcheck.js isn't loaded and there's no chrome.storage.local, so nothing is
// fetched. Returns the redirects it asked for plus hooks for SPA navigation
// and popup setting changes.
function loadPage(path, { session, settings = {}, now = T0 }) {
  const redirects = [];
  const intervals = [];
  let onChanged = null;
  const location = {
    origin: "https://www.reddit.com",
    pathname: path,
    replace: (url) => redirects.push(url),
  };
  const el = () => ({ classList: { toggle() {}, add() {}, remove() {}, contains: () => false } });
  const sandbox = {
    location,
    sessionStorage: session,
    console: { warn() {} },
    Date: { now: () => now },
    requestAnimationFrame: () => {},
    setInterval: (fn) => intervals.push(fn),
    setTimeout: () => {},
    MutationObserver: class { observe() {} },
    document: { body: el(), documentElement: el(), querySelectorAll: () => [] },
    chrome: {
      runtime: { id: "x", sendMessage() {}, onMessage: { addListener() {} } },
      storage: {
        sync: { get: (defaults, cb) => cb({ ...defaults, ...settings }) },
        onChanged: { addListener: (fn) => (onChanged = fn) },
      },
    },
  };
  runInNewContext(src, sandbox);
  return {
    redirects,
    spaNavigate(newPath) {
      location.pathname = newPath;
      intervals.forEach((fn) => fn());
    },
    popupSet(key, value) {
      onChanged({ [key]: { newValue: value } }, "sync");
    },
  };
}

let failed = 0;
function check(name, cond) {
  if (cond) console.log(`  ok   ${name}`);
  else {
    failed++;
    console.log(`  FAIL ${name}`);
  }
}

console.log("reddit-remove-promoted-keep-rising: Rising redirect");

{
  const session = makeSessionStorage();
  const first = loadPage("/", { session });
  check("redirects the default home feed to /rising/",
    first.redirects.length === 1 && first.redirects[0] === "https://www.reddit.com/rising/");

  // Reddit bounces /rising/ back to "/": the reload lands on "/" again.
  const bounced = loadPage("/", { session, now: T0 + 800 });
  check("does not redirect again after Reddit bounces back (no reload loop)",
    bounced.redirects.length === 0);

  const later = loadPage("/", { session, now: T0 + 60_000 });
  check("stays given up for the rest of the tab", later.redirects.length === 0);
  later.spaNavigate("/best/");
  check("SPA navigation back home also stays given up", later.redirects.length === 0);

  later.popupSet("sortRising", true);
  check("switching Keep Rising back on retries once", later.redirects.length === 1);
}

{
  const session = makeSessionStorage();
  loadPage("/", { session });
  const page = loadPage("/rising/", { session, now: T0 + 500 });
  check("leaves /rising/ alone", page.redirects.length === 0);
  page.spaNavigate("/r/newzealand/");
  check("leaves subreddits alone", page.redirects.length === 0);

  // /rising/ stuck, so a genuine trip back home later should redirect again.
  const later = loadPage("/", { session, now: T0 + 30_000 });
  check("a real return home after the bounce window redirects normally",
    later.redirects.length === 1);
}

{
  const page = loadPage("/", { session: makeSessionStorage(), settings: { enabled: false } });
  check("master Enable switch off → no redirect", page.redirects.length === 0);
}

{
  const page = loadPage("/rising/", { session: makeSessionStorage() });
  page.popupSet("enabled", false);
  page.spaNavigate("/");
  check("Enable switched off in the popup → clicking Home doesn't redirect",
    page.redirects.length === 0);
  page.popupSet("enabled", true);
  check("Enable switched back on → redirects again", page.redirects.length === 1);
}

{
  const page = loadPage("/", { session: makeSessionStorage(), settings: { sortRising: false } });
  check("Keep Rising off → no redirect", page.redirects.length === 0);
}

{
  const throwing = {
    getItem() { throw new Error("blocked"); },
    setItem() { throw new Error("blocked"); },
    removeItem() { throw new Error("blocked"); },
  };
  const page = loadPage("/", { session: throwing });
  check("sessionStorage unavailable → fail safe, no redirect", page.redirects.length === 0);
}

if (failed) {
  console.log(`\n${failed} failing`);
  process.exit(1);
}
console.log("\nall passed");
