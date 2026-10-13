# Reddit: Hide Promoted & Keep Rising

A Chrome extension that removes **Promoted / Sponsored** ads from the Reddit home
feed and **keeps the feed sorted by Rising** instead of the default "Best".

## How it works

Reddit's current UI ("shreddit") is built from clean semantic web components, so
no de-obfuscation is needed:

- **Hide ads** — every feed ad is a `<shreddit-ad-post>` element (a direct child
  of `<shreddit-feed>`, carrying a `promoted` attribute), separated from real
  posts by `<hr>` rules. Organic posts are `<article>` wrappers around
  `<shreddit-post>`. The extension hides each `<shreddit-ad-post>` plus its
  trailing `<hr>` so no double divider is left behind.
- **Keep Rising** — the home feed defaults to "Best"; the Rising sort lives at
  `/rising/`. Whenever you land on or navigate back to the default home feed
  (`/`, `?feed=home`, or `/best/`) the extension redirects to `/rising/` (a full
  page load). Explicit sorts you pick (`/hot/`, `/new/`, `/top/`, …) and
  subreddits are left alone.
- **Reload-loop guard** — the extension doesn't control what Reddit does with
  `/rising/`. If Reddit sends it straight back to the default feed, redirecting
  again would reload the tab forever. So each redirect is timestamped in the
  tab's `sessionStorage`; landing back on the default feed within 5 seconds
  counts as a bounce, and the extension stops redirecting in that tab (a warning
  is logged to the console). Worst case is one wasted reload per tab, after
  which you stay on Best. If `sessionStorage` is unavailable, it doesn't
  redirect at all rather than risk a loop.

A `MutationObserver` re-applies the ad filter as you scroll and as the feed
lazy-loads more posts.

## Install (unpacked)

1. Open `chrome://extensions`.
2. Toggle **Developer mode** on (top-right).
3. Click **Load unpacked** and select this folder
   (`reddit-remove-promoted-keep-rising`).
4. Open [Reddit](https://www.reddit.com/). The home feed opens on Rising with ads
   stripped.

## Options (toolbar popup)

- **Enable** — master on/off.
- **Hide Promoted / Sponsored** — remove ad posts.
- **Keep feed sorted by Rising** — redirect default home (Best) → Rising.
- **Dim instead of remove** — fade & collapse hidden posts (hover to peek).
- A live counter of how many promoted posts were hidden on the page.

## Data it stores

- `chrome.storage.sync` — your four popup toggles. Nothing else.
- The page's `sessionStorage` on `www.reddit.com` — two keys used only by the
  reload-loop guard: `rrf-rising-redirect-at` (timestamp of the last redirect)
  and `rrf-rising-gave-up` (set once a bounce is detected). Reddit's own scripts
  can read the page's `sessionStorage`; neither key holds anything about you.
  Both are cleared when the tab closes.

Nothing leaves your machine: no network requests, no analytics.

## Security

Follows the shared [security guidelines](../SECURITY.md) (OWASP Browser
Extension Vulnerabilities Cheat Sheet): `storage`-only permission, HTTPS-only
top-frame content script, strict CSP, no `innerHTML`/`eval`, no remote code, no
network calls, and `sender.id`-validated messaging. Enforced by
`npm test` (`../tests/owasp-audit.mjs`).

## Files

| File | Purpose |
|------|---------|
| `manifest.json` | MV3 manifest, content script + popup |
| `content.js` | Ad hiding, Rising-sort redirect, `MutationObserver` |
| `content.css` | `display:none` (and optional dim) styling, gated on `html.rrf-active` |
| `popup.html` / `popup.css` / `popup.js` | Toolbar settings + hidden counter |

## Notes

- If Reddit renames the ad element, adjust the selector in
  [`content.js`](content.js) (`shreddit-ad-post`).
- Only the new `www.reddit.com` design is supported (not `old.reddit.com`).
- If the tab keeps landing on Best instead of Rising, Reddit is probably
  redirecting `/rising/` away and the loop guard has stepped in. Check the
  console for `[Reddit Declutter]`, or switch off **Keep feed sorted by Rising**.
- The bounce guard can misfire if you click Home within 5 seconds of being
  redirected to Rising. You stay on Best for that tab; a new tab resets it.
- The **Enable** master switch now turns off the Rising redirect too (in 1.0.0
  it only turned off ad hiding).
- Redirect-loop behaviour is covered by `../tests/reddit-rising.test.mjs`.
