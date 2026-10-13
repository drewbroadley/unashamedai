# Reddit: Hide Promoted & Keep Rising

A Chrome extension that removes **Promoted / Sponsored** ads from the Reddit home
feed, **keeps the feed sorted by Rising** instead of the default "Best", and
**hides posts and comments from accounts that look like bots**.

## How it works

Reddit's current UI ("shreddit") is built from clean semantic web components, so
no de-obfuscation is needed:

- **Hide ads** — every feed ad is a `<shreddit-ad-post>` element (a direct child
  of `<shreddit-feed>`, carrying a `promoted` attribute), separated from real
  posts by `<hr>` rules. Organic posts are `<article>` wrappers around
  `<shreddit-post>`. The extension hides each `<shreddit-ad-post>` plus its
  trailing `<hr>` so no double divider is left behind.
- **Keep Rising** — the home feed defaults to "Best"; the Rising sort lives at
  the stable URL `/rising/`. Whenever you land on or navigate back to the default
  home feed (`/`, `?feed=home`, or `/best/`) the extension redirects to
  `/rising/`. Explicit sorts you pick (`/hot/`, `/new/`, `/top/`, …) are left
  alone. If Reddit sends the tab straight back to the home feed (for example by rewriting
  `/rising/` back to `/`), the extension stops redirecting in that
  tab instead of reloading forever; it remembers this with two small per-tab
  flags in `sessionStorage`.
- **Hide likely bots** — every post (`<shreddit-post>`) and comment
  (`<shreddit-comment>`) carries an `author` attribute. For each author on the
  page the extension reads their public profile and scores it (below). When
  the score reaches your threshold, their posts are hidden from feeds and their
  comments are hidden in threads.

A `MutationObserver` re-applies everything as you scroll and as the feed or
thread lazy-loads more content.

### How an account is scored

Two public, unauthenticated JSON endpoints Reddit serves for every profile:

1. `/user/<name>/about.json` — account creation date and karma. Always read.
2. `/user/<name>/overview.json?limit=50` — the account's 50 most recent posts
   and comments. Only read when step 1 didn't decide it *and* the account isn't
   obviously established (under a year old or under 1,000 karma). Can be turned
   off ("Check recent activity").

Each signal adds points; the author is hidden when the total reaches **Hide at
score** (default 3).

| Signal | Points |
|--------|-------:|
| Profile returns 404 (shadowbanned or deleted) | 3 |
| Account suspended | 3 |
| Account younger than **Min age** (default 30 days) | 2 |
| …and younger than 7 days | +1 |
| Total karma under **Min karma** (default 20) | 1 |
| Reddit's auto-generated username shape (`Adjective-Noun-1234`) | 1 |
| ≥1,000 post karma with almost no comment karma (karma farming) | 1 |
| *Recent activity:* ≥5 posts and zero comments | 1 |
| *Recent activity:* the same comment (≥20 chars) posted 3+ times | 2 |
| *Recent activity:* 25+ posts/comments inside 24 hours | 2 |
| *Recent activity:* account over 6 months old whose entire history is from the last 30 days (aged/bought account) | 2 |

So with the defaults: a 2-day-old account with no karma is hidden; a 3-week-old
account with real karma is not, unless something else also looks off; an old
account with plenty of karma never is. The scoring lives in
[`botcheck.js`](botcheck.js) and is unit-tested in
[`../tests/botcheck.test.mjs`](../tests/botcheck.test.mjs).

What gets hidden:

- **Feeds** (home, subreddits, search): the whole post card.
- **Comments**: only the bot's own avatar, header, text and action row. Replies
  from other people nested under it stay visible.
- The post you deliberately opened is never hidden, even if its author is
  flagged (it still shows up in the popup's list).
- `[deleted]` authors are skipped.

### Seeing what was hidden

- The popup lists every account flagged on the current page, with its score and
  the reasons. **Not a bot** adds that username to an allowlist so it's never
  hidden again (and un-hides it immediately). **Forget my "not a bot" list**
  clears it.
- **Dim instead of remove** fades and collapses hidden posts and comments
  instead of removing them; hover one to read it.

## Install (unpacked)

1. Open `chrome://extensions`.
2. Toggle **Developer mode** on (top-right).
3. Click **Load unpacked** and select this folder
   (`reddit-remove-promoted-keep-rising`).
4. Open [Reddit](https://www.reddit.com/). The home feed opens on Rising with ads
   stripped, and likely-bot posts and comments disappear a moment after the page
   loads (each profile takes one request to check).

If you already had an earlier version loaded, press the reload icon on its card in
`chrome://extensions`.

## Options (toolbar popup)

- **Enable** — master on/off.
- **Hide Promoted / Sponsored** — remove ad posts.
- **Keep feed sorted by Rising** — redirect default home (Best) → Rising.
- **Dim instead of remove** — fade & collapse hidden posts (hover to peek).
- **Hide likely bots** — the whole bot feature on/off (on by default).
  - **In feeds** / **In comments** — where to hide them.
  - **Check recent activity** — allow the second (`overview.json`) lookup.
  - **Min age (days)**, **Min karma**, **Hide at score** — the thresholds above.
- Live counters of promoted posts and bot posts/comments hidden on the page, the
  list of flagged accounts, and how many profiles are still waiting to be
  checked.

## What it can touch

| Manifest entry | Why it is there |
|----------------|-----------------|
| `permissions: ["storage"]` | Popup settings and the "not a bot" list in `chrome.storage.sync`; the profile cache in `chrome.storage.local`. The only permission requested. |
| `host_permissions` | **None.** The profile lookups go to `www.reddit.com`, the page the script is already running on, so they are same-origin and need no host permission. |
| `content_scripts.matches: ["https://www.reddit.com/*"]` | HTTPS only, and only Reddit. No other site is touched. |
| `content_scripts.js: ["botcheck.js", "content.js"]` | The scorer (pure functions) and the page logic. |
| `content_scripts.all_frames: false` | Top-level document only. |
| `run_at: "document_start"` | So the Rising redirect and ad hiding happen before the page renders. |
| `content_security_policy` | `script-src 'self'`: no remote code, no `eval`, no inline script. |

## What data it reads, stores, or sends

- **Reads** the `author` attribute of posts and comments on the page, and the
  public profile JSON described above. It does not read post or comment text on
  the page.
- **Network:** only `GET https://www.reddit.com/user/<name>/about.json` and, for
  borderline accounts, `.../overview.json?limit=50`. These are same-origin
  requests from the Reddit tab, so Reddit sees them the way it sees the page
  itself (your Reddit cookies go with them, as with any Reddit page request);
  in practice that means **Reddit learns which profiles were looked up from your
  session**. Nothing is sent to any other server. No analytics, no telemetry.
  Requests go one at a time, at most one every 1.5 seconds, and back off
  entirely if Reddit answers `429 Too Many Requests`. Usernames are checked
  against Reddit's username rules (`[A-Za-z0-9_-]{3,20}`) before they go into a
  URL.
- **Stores** in `chrome.storage.local`, per username: creation date, karma, and
  from the activity lookup only counts (posts, comments, the time span, the
  most-repeated comment count). **No comment or post text is kept.** Entries
  expire after 24 hours and the cache is capped at 5,000 accounts.
- **Stores** in `chrome.storage.sync`: your toggles, thresholds, and the "not a
  bot" usernames (up to 300).

## What it does not do

- Does not vote, post, comment, report, block or subscribe on your behalf.
- Does not read cookies, tokens or credentials (the browser attaches Reddit's
  own cookies to the same-origin requests; the extension never sees them).
- Does not load code from anywhere.
- Does not inject any UI into Reddit; everything you interact with is in the
  popup.

## Honest caveats

- **This is a heuristic, not a verdict.** New humans get caught (a brand-new
  account with no karma looks exactly like a fresh bot), and patient bots on aged
  accounts with farmed karma get through. Tune the thresholds, use **Not a bot**,
  or turn on **Dim** if you want to see what's being hidden.
- **Big threads take a while.** One request per new author, at most ~40 a
  minute, so a thread with hundreds of distinct commenters fills in over several
  minutes, top of the page first. Already-checked accounts (cached for a day)
  are instant.
- **Reddit's rate limits are undocumented** for this kind of request. The
  throttle is conservative and the extension backs off on `429`, but if Reddit
  tightens things lookups will slow down or stall. Errors (network failure,
  private profile, anything not a clean 200/404) are never treated as a bot
  signal; that author simply stays visible.
- A 404 profile is treated as a strong signal (shadowbanned). Deleted accounts
  also 404, but Reddit shows their author as `[deleted]`, which is skipped, so a
  deleted human should rarely be caught by this.
- Comment hiding targets the comment's `slot="commentAvatar" / "commentMeta" /
  "comment" / "actionRow"` children. If Reddit renames those, the extension falls
  back to hiding the whole comment (including replies under it).
- **Keep Rising can be overridden by Reddit.** Version 1.1.0 and earlier could
  reload endlessly when Reddit bounced `/rising/` back to `/`; 1.1.1 detects
  the bounce and gives up for that tab, so you may see the Best sort on those
  accounts. Toggling the option off and on again retries. Before 1.1.2 the
  **Enable** master switch didn't stop the redirect; now it does. Covered by
  [`../tests/reddit-rising.test.mjs`](../tests/reddit-rising.test.mjs).
- Only the new `www.reddit.com` design is supported (not `old.reddit.com`).
- If Reddit renames the ad element, adjust the selector in
  [`content.js`](content.js) (`shreddit-ad-post`).

## Security

Follows the shared [security guidelines](../SECURITY.md) (OWASP Browser
Extension Vulnerabilities Cheat Sheet): `storage`-only permission, HTTPS-only
top-frame content script, strict CSP, no `innerHTML`/`eval`, no remote code, and
`sender.id`-validated messaging. The popup renders usernames and reasons with
`textContent` only. The one network path is the same-origin profile lookup
described above. Enforced by `npm test` (`../tests/owasp-audit.mjs`).

## Files

| File | Purpose |
|------|---------|
| `manifest.json` | MV3 manifest, content script + popup |
| `botcheck.js` | Bot scoring: turns profile JSON into features and a score. No DOM, no network |
| `content.js` | Ad hiding, Rising-sort redirect, profile lookups + cache, bot hiding, `MutationObserver` |
| `content.css` | `display:none` (and optional dim) styling, gated on `html.rrf-active` |
| `popup.html` / `popup.css` / `popup.js` | Toolbar settings, counters, flagged-account list |
