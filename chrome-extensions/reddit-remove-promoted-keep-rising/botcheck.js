/*
 * Likely-bot scoring for Reddit accounts.
 * --------------------------------------------------------------------------
 * Pure functions, no DOM and no network, so they can be unit-tested in Node
 * (tests/botcheck.test.mjs). content.js fetches the public profile JSON and
 * hands it to extractFeatures(); the compact feature object is what gets
 * cached, and score() turns it into a verdict using the user's thresholds.
 *
 * Caching features (not verdicts) means changing a threshold in the popup
 * re-scores every author instantly, without re-fetching anything.
 *
 * Exposed as globalThis.RedditBotCheck (content scripts share one global).
 */
(function (root) {
  "use strict";

  const DAY = 86400;

  const DEFAULT_THRESHOLDS = {
    botMinAgeDays: 30, // accounts younger than this look suspicious
    botMinKarma: 20, // total karma below this looks suspicious
    botScoreThreshold: 3, // hide when the summed signal weights reach this
  };

  // Reddit's auto-suggested usernames: Adjective-Noun-1234, Word_Word1234.
  const AUTO_NAME_RE = /^[A-Z][a-z]+(?:[-_][A-Z][a-z]+){1,2}[-_]?\d{1,5}$/;

  // Usernames Reddit allows: 3-20 chars of letters, digits, _ and -.
  const VALID_NAME_RE = /^[A-Za-z0-9_-]{3,20}$/;

  function isCheckableName(name) {
    return typeof name === "string" && VALID_NAME_RE.test(name);
  }

  function normaliseBody(s) {
    return String(s || "")
      .toLowerCase()
      .replace(/https?:\/\/\S+/g, "")
      .replace(/[^a-z0-9]+/g, " ")
      .trim();
  }

  /**
   * Boil the about.json response down to the handful of numbers score()
   * needs.
   *
   * @param {object|null} about   parsed /user/<name>/about.json, or null
   * @param {number}      status  HTTP status of that request
   */
  function extractFeatures(about, status) {
    if (status === 404) return { missing: true };
    const d = (about && about.data) || {};
    if (d.is_suspended) return { suspended: true };
    const link = Number(d.link_karma) || 0;
    const comment = Number(d.comment_karma) || 0;
    return {
      name: typeof d.name === "string" ? d.name : "",
      createdUtc: Number(d.created_utc) || 0,
      linkKarma: link,
      commentKarma: comment,
      totalKarma: Number(d.total_karma ?? link + comment) || 0,
    };
  }

  /**
   * Summarise recent activity from /user/<name>/overview.json: how many posts
   * and comments, over what time span, and how often the same comment was
   * repeated. Only counts and timestamps are returned; no text is kept.
   */
  function extractActivity(overview) {
    const data = overview && overview.data;
    const kids = data && Array.isArray(data.children) ? data.children : [];
    let posts = 0;
    let comments = 0;
    let oldest = Infinity;
    let newest = 0;
    let maxRepeat = 0;
    const seen = new Map();
    for (const k of kids) {
      const kd = k && k.data;
      if (!kd) continue;
      if (k.kind === "t3") posts++;
      else if (k.kind === "t1") {
        comments++;
        const body = normaliseBody(kd.body);
        if (body.length >= 20) {
          const n = (seen.get(body) || 0) + 1;
          seen.set(body, n);
          if (n > maxRepeat) maxRepeat = n;
        }
      } else continue;
      const t = Number(kd.created_utc) || 0;
      if (t && t < oldest) oldest = t;
      if (t > newest) newest = t;
    }
    return {
      posts,
      comments,
      oldestUtc: oldest === Infinity ? 0 : oldest,
      newestUtc: newest,
      // No "after" cursor means this is the account's whole visible history.
      complete: !(data && data.after),
      maxRepeat,
    };
  }

  /**
   * Score a feature object. Returns { score, reasons, flagged }.
   * Each reason is a short human-readable string shown in the popup.
   */
  function score(f, thresholds, nowSec) {
    const t = { ...DEFAULT_THRESHOLDS, ...(thresholds || {}) };
    const now = nowSec || Math.floor(Date.now() / 1000);
    const reasons = [];
    let s = 0;
    const add = (w, why) => {
      s += w;
      reasons.push(why);
    };

    if (!f) return { score: 0, reasons, flagged: false };
    if (f.missing) add(3, "profile not found (shadowbanned or deleted)");
    if (f.suspended) add(3, "account suspended");

    if (!f.missing && !f.suspended) {
      const ageDays = f.createdUtc ? (now - f.createdUtc) / DAY : Infinity;
      if (ageDays < t.botMinAgeDays) {
        add(2, `account is ${Math.max(0, Math.floor(ageDays))} days old`);
        if (ageDays < 7) add(1, "less than a week old");
      }
      if (f.totalKarma < t.botMinKarma) add(1, `only ${f.totalKarma} karma`);
      if (f.name && AUTO_NAME_RE.test(f.name)) add(1, "auto-generated username");
      if (f.linkKarma >= 1000 && f.commentKarma * 50 < f.linkKarma) {
        add(1, "post karma with almost no comment karma (karma farming)");
      }

      const r = f.recent;
      if (r) {
        const items = r.posts + r.comments;
        if (r.posts >= 5 && r.comments === 0) add(1, "posts but never comments");
        if (r.maxRepeat >= 3) add(2, `repeated the same comment ${r.maxRepeat} times`);
        if (items >= 25 && r.newestUtc - r.oldestUtc < DAY) {
          add(2, `${items} posts/comments inside 24 hours`);
        }
        if (
          r.complete &&
          items >= 5 &&
          ageDays > 180 &&
          r.oldestUtc &&
          now - r.oldestUtc < 30 * DAY
        ) {
          add(2, "old account that was silent until this month");
        }
      }
    }

    return { score: s, reasons, flagged: s >= t.botScoreThreshold };
  }

  /**
   * Whether the overview.json lookup is worth a second request: only when
   * about.json alone hasn't decided it and the account isn't obviously an
   * established one.
   */
  function needsActivityCheck(f, thresholds, nowSec) {
    if (!f || f.missing || f.suspended || f.recent) return false;
    if (score(f, thresholds, nowSec).flagged) return false;
    const now = nowSec || Math.floor(Date.now() / 1000);
    const ageDays = f.createdUtc ? (now - f.createdUtc) / DAY : Infinity;
    return ageDays < 365 || f.totalKarma < 1000;
  }

  root.RedditBotCheck = {
    DEFAULT_THRESHOLDS,
    isCheckableName,
    extractFeatures,
    extractActivity,
    score,
    needsActivityCheck,
  };
})(globalThis);
