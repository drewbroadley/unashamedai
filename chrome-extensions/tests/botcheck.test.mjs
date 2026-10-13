#!/usr/bin/env node
/*
 * Tests for reddit-remove-promoted-keep-rising/botcheck.js, the likely-bot
 * scorer. The fixtures mirror the shape of Reddit's public
 * /user/<name>/about.json and /user/<name>/overview.json responses.
 *
 * Run:  node tests/botcheck.test.mjs
 */
import { readFileSync } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";
import { runInNewContext } from "node:vm";

const ROOT = join(dirname(fileURLToPath(import.meta.url)), "..");
const src = readFileSync(
  join(ROOT, "reddit-remove-promoted-keep-rising", "botcheck.js"),
  "utf8"
);
const sandbox = { globalThis: null };
sandbox.globalThis = sandbox;
runInNewContext(src, sandbox);
const BC = sandbox.RedditBotCheck;

const NOW = 1_760_000_000; // fixed clock
const DAY = 86400;

let failures = 0;
let passed = 0;
function ok(cond, name, detail = "") {
  if (cond) passed++;
  else {
    failures++;
    console.error(`  ✗ ${name}${detail ? `  — ${detail}` : ""}`);
  }
}

const about = (o) => ({ kind: "t2", data: { name: "someone", ...o } });
const feat = (o) => BC.extractFeatures(about(o), 200);
const verdict = (f, t) => BC.score(f, t, NOW);

// ---- extractFeatures ---------------------------------------------------------
{
  const f = feat({ created_utc: NOW - 10 * DAY, link_karma: 5, comment_karma: 2, total_karma: 7 });
  ok(f.totalKarma === 7 && f.linkKarma === 5 && f.commentKarma === 2, "reads karma");
  ok(f.createdUtc === NOW - 10 * DAY, "reads created_utc");
  ok(BC.extractFeatures(null, 404).missing === true, "404 means missing / shadowbanned");
  ok(BC.extractFeatures(about({ is_suspended: true }), 200).suspended === true, "suspended flag");
  const noTotal = feat({ created_utc: 1, link_karma: 3, comment_karma: 4 });
  ok(noTotal.totalKarma === 7, "falls back to link+comment when total_karma absent");
}

// ---- Established human: never flagged ----------------------------------------
{
  const f = feat({ name: "spez", created_utc: NOW - 6000 * DAY, link_karma: 900000, comment_karma: 700000 });
  const v = verdict(f);
  ok(!v.flagged && v.score === 0, "old high-karma account scores 0", JSON.stringify(v));
  ok(!BC.needsActivityCheck(f, {}, NOW), "established account skips the activity lookup");
}

// ---- Brand new, no karma: flagged on about.json alone ------------------------
{
  const f = feat({ created_utc: NOW - 2 * DAY, link_karma: 1, comment_karma: 0 });
  const v = verdict(f);
  ok(v.flagged, "2-day-old 1-karma account is flagged", JSON.stringify(v));
  ok(v.reasons.some((r) => /days old/.test(r)), "reason names the age");
  ok(!BC.needsActivityCheck(f, {}, NOW), "already-flagged account skips the activity lookup");
}

// ---- New-ish but active human: below default threshold ----------------------
{
  const f = feat({ name: "real_person", created_utc: NOW - 20 * DAY, link_karma: 40, comment_karma: 300 });
  const v = verdict(f);
  ok(!v.flagged && v.score === 2, "20-day-old account with karma scores 2, not hidden", JSON.stringify(v));
  ok(BC.needsActivityCheck(f, {}, NOW), "borderline account gets the activity lookup");
}

// ---- Auto-generated username adds a point ------------------------------------
{
  const f = feat({ name: "Spiritual-Ad-1234", created_utc: NOW - 20 * DAY, link_karma: 40, comment_karma: 300 });
  ok(verdict(f).flagged, "new + auto-generated name reaches 3");
  const old = feat({ name: "Spiritual-Ad-1234", created_utc: NOW - 900 * DAY, link_karma: 400, comment_karma: 3000 });
  ok(!verdict(old).flagged, "auto-generated name alone is not enough");
}

// ---- Missing / suspended ------------------------------------------------------
ok(verdict(BC.extractFeatures(null, 404)).flagged, "shadowbanned profile is flagged");
ok(verdict(BC.extractFeatures(about({ is_suspended: true }), 200)).flagged, "suspended is flagged");

// ---- Thresholds come from the popup ------------------------------------------
{
  const f = feat({ created_utc: NOW - 20 * DAY, link_karma: 40, comment_karma: 300 });
  ok(verdict(f, { botScoreThreshold: 2 }).flagged, "lower threshold flags borderline account");
  ok(!verdict(f, { botMinAgeDays: 7 }).flagged && verdict(f, { botMinAgeDays: 7 }).score === 0, "min age setting respected");
  const lowKarma = feat({ created_utc: NOW - 900 * DAY, link_karma: 5, comment_karma: 5 });
  ok(verdict(lowKarma).score === 1, "karma under default 20 adds 1");
  ok(verdict(lowKarma, { botMinKarma: 5 }).score === 0, "min karma setting respected");
}

// ---- Karma farming --------------------------------------------------------------
{
  const f = feat({ created_utc: NOW - 60 * DAY, link_karma: 25000, comment_karma: 12 });
  const v = verdict(f);
  ok(v.reasons.some((r) => /karma farming/.test(r)), "post-only karma is noticed", JSON.stringify(v));
}

// ---- extractActivity + activity signals ---------------------------------------
const t3 = (t) => ({ kind: "t3", data: { created_utc: t, title: "x" } });
const t1 = (t, body = "some unique comment " + t) => ({ kind: "t1", data: { created_utc: t, body } });
const overview = (children, after = null) => ({ kind: "Listing", data: { after, children } });

{
  const a = BC.extractActivity(overview([t3(NOW - 100), t1(NOW - 50), t1(NOW - 10)], "t1_abc"));
  ok(a.posts === 1 && a.comments === 2, "counts posts and comments");
  ok(a.oldestUtc === NOW - 100 && a.newestUtc === NOW - 10, "tracks time span");
  ok(a.complete === false, "after cursor means history continues");
  ok(!("body" in a) && !JSON.stringify(a).includes("unique comment"), "keeps no comment text");
  ok(BC.extractActivity(null).posts === 0, "tolerates missing overview");
}

const base = { name: "x", createdUtc: NOW - 60 * DAY, linkKarma: 100, commentKarma: 100, totalKarma: 200 };

{
  const spam = "Check out my amazing crypto giveaway at this link now!";
  const a = BC.extractActivity(overview([t1(NOW - 30, spam), t1(NOW - 20, spam + " "), t1(NOW - 10, spam.toUpperCase())]));
  ok(a.maxRepeat === 3, "normalised duplicate comments counted", String(a.maxRepeat));
  ok(verdict({ ...base, recent: a }).score === 2, "repeated comment adds 2");
}
{
  const a = BC.extractActivity(overview(Array.from({ length: 30 }, (_, i) => t1(NOW - i * 60))));
  ok(verdict({ ...base, recent: a }).reasons.some((r) => /inside 24 hours/.test(r)), "burst posting noticed");
}
{
  const a = BC.extractActivity(overview(Array.from({ length: 6 }, (_, i) => t3(NOW - i * 3 * DAY))));
  ok(verdict({ ...base, recent: a }).reasons.includes("posts but never comments"), "post-only history noticed");
}
{
  const dormant = { ...base, createdUtc: NOW - 1500 * DAY };
  const a = BC.extractActivity(overview(Array.from({ length: 8 }, (_, i) => t1(NOW - i * 2 * DAY))));
  ok(verdict({ ...dormant, recent: a }).reasons.some((r) => /silent until/.test(r)), "aged-then-woken account noticed");
  const partial = BC.extractActivity(overview(Array.from({ length: 8 }, (_, i) => t1(NOW - i * 2 * DAY)), "t1_more"));
  ok(!verdict({ ...dormant, recent: partial }).reasons.some((r) => /silent until/.test(r)), "not claimed when history is truncated");
}
{
  // A normal human: mixed posts and comments spread over weeks.
  const kids = [];
  for (let i = 0; i < 40; i++) kids.push(i % 5 ? t1(NOW - i * DAY) : t3(NOW - i * DAY));
  const a = BC.extractActivity(overview(kids, "t1_more"));
  ok(verdict({ ...base, recent: a }).score === 0, "ordinary activity adds nothing");
}

// ---- Username validation (guards the fetch path) --------------------------------
ok(BC.isCheckableName("Spiritual-Ad-1234"), "accepts normal names");
ok(!BC.isCheckableName("[deleted]"), "skips [deleted]");
ok(!BC.isCheckableName("../../api/me"), "rejects path tricks");
ok(!BC.isCheckableName(""), "rejects empty");

console.log(`\nbotcheck: ${passed}/${passed + failures} tests passed.`);
if (failures) process.exit(1);
