# YouTube: Clear Watch Later

A Chrome extension that **empties your YouTube Watch Later playlist in about a
minute**, instead of three clicks per video. It removes up to **500 videos per
request**, oldest-added first, and keeps a list of everything it removed so you
can download it.

## Why this is fast

YouTube has no "remove all" for Watch Later. Its only bulk option is **Remove
watched videos** (in the playlist's ⋮ menu), which leaves everything you never
started. Doing it by hand means ⋮ → **Remove from Watch later** for every video.

That menu item sends one request to YouTube's own web API:

```
POST https://www.youtube.com/youtubei/v1/browse/edit_playlist
{ "playlistId": "WL",
  "actions": [ { "action": "ACTION_REMOVE_VIDEO", "setVideoId": "…" } ] }
```

`actions` is a list. The web page only ever puts one item in it, but the
endpoint accepts many. Measured against a real 4,681-video Watch Later in
November 2026:

| Videos in one request | Time for the request |
|----------------------:|---------------------:|
| 5 | 3.8 s |
| 100 | 3.9 s |
| 200 | 4.1 s |
| 500 | 4.4 s |

The time barely changes with batch size, so the extension sends 500 per
request (the largest size tested; bigger may work but hasn't been tried).
Listing the playlist is the slower part: YouTube returns it 100 entries at a
time, about 0.7 s per page, so 4,681 videos took 46 requests and about 30
seconds. A full clear of that list is roughly 30 s of listing plus 10 removal
requests, about a minute and a quarter in total.

## How it works

1. **Count.** When you open the popup it makes one request for the first page
   of Watch Later and shows the playlist's video count.
2. **List.** When you confirm, it pages through the whole playlist
   (`/youtubei/v1/browse`, browse id `VLWL`) collecting each entry's
   `setVideoId` (the id of that entry in the playlist), video id and title. It
   asks YouTube to include **unavailable videos** (deleted or private), which
   the page normally hides but which still count against the 5,000 limit.
3. **Remove, oldest-added first,** 500 per request. If you stop half way, the
   videos you added most recently are the ones left.
4. **Check again.** It re-lists the playlist and makes another pass if anything
   is left (up to three passes), for example videos added while it ran.
5. **Reload** the tab if you're looking at the Watch Later page, so you see it
   empty.

If YouTube rejects a batch as a bad request (usually one entry that changed
since it was listed), the batch is split in half and retried, down to single
entries; one that still fails is skipped and counted. Rate limits (`429`) and
server errors are retried with backoff (2, 4, 8, 16 s) before giving up. There
is a 0.3 s pause between requests.

### Signing the requests (the one sensitive thing it does)

YouTube's API ignores your sign-in cookies unless the request also carries the
`Authorization: SAPISIDHASH …` header that YouTube's own page computes. Without
it, removals "succeed" while doing nothing, because the API treats you as
signed out. So the extension computes the same header the page does:

```
SAPISIDHASH <unix time>_<SHA-1 of "<unix time> <SAPISID cookie> https://www.youtube.com">
```

(plus the `SAPISID1PHASH` / `SAPISID3PHASH` variants from the
`__Secure-1PAPISID` / `__Secure-3PAPISID` cookies when they exist.)

To do that the content script **reads those cookie values with
`document.cookie`** inside the YouTube tab, at the moment it sends each
request. The values are hashed and sent only to `www.youtube.com` in the
header above, exactly as YouTube's own page sends them. They are never
stored, logged, shown in the popup, or sent anywhere else. This is different
from the other extensions in this repo, which never touch cookies; it is the
price of doing this through the API instead of clicking through menus.

The page settings the API needs (client version, session index, and the
brand-account id if you're acting as a brand account) are read from YouTube's
own inline `ytcfg.set({...})` script on the page.

## Install (unpacked)

1. Open `chrome://extensions`.
2. Toggle **Developer mode** on (top-right).
3. Click **Load unpacked** and select this folder (`youtube-clear-watch-later`).
4. Open or **reload** a YouTube tab (any page on `www.youtube.com`, signed in).
   Tabs that were already open before you installed it need a reload.
5. Click the toolbar icon.

## Using it

- The popup shows how many videos are in Watch Later.
- **Clear Watch Later** turns into **Yes, remove all N** for five seconds;
  click it again to start. (No browser confirm dialog.)
- A progress bar shows the listing, then the removals. **Stop** finishes the
  current request and stops; the newest videos are kept.
- You can close the popup while it runs; the work happens in the YouTube tab.
  Reopen the popup on that tab to see progress. Closing or reloading the
  **tab** stops it.
- **Removed list**: every video it removed (across runs, until you clear it)
  is listed by count. **Download list (CSV)** saves `url,title` for each one,
  so you can re-add anything you didn't mean to lose. **Forget list** deletes
  it.

## What it can touch

| Manifest entry | Why it is there |
|----------------|-----------------|
| `permissions: ["storage"]` | The removed-videos list in `chrome.storage.local`. The only permission requested. |
| `host_permissions` | **None.** Every request goes to `www.youtube.com`, the page the script is already running on, so they are same-origin. |
| `content_scripts.matches: ["https://www.youtube.com/*"]` | HTTPS only, and only YouTube's main site. Not `m.youtube.com`, not `music.youtube.com`, not any other site. |
| `content_scripts.js: ["innertube.js", "content.js"]` | The API helpers (pure functions, unit-tested) and the worker that runs a clear when the popup asks. |
| `content_scripts.all_frames: false` | Top-level document only; nothing runs in embedded YouTube players on other sites. |
| `run_at: "document_idle"` | It only needs the page's settings script, which is there by then. Nothing happens until you click. |
| `content_security_policy` | `script-src 'self'`: no remote code, no `eval`, no inline script. |

The `tabs` permission is **not** requested. The popup finds "the tab you're
on" with `chrome.tabs.query`, which returns the tab id without it; the
extension never reads tab URLs or titles.

## What data it reads, stores, or sends

- **Reads** from the page: the inline `ytcfg` settings script, and the
  `SAPISID`, `__Secure-1PAPISID` and `__Secure-3PAPISID` cookies (see above).
  It does not read the page's video list, comments or anything you've typed.
- **Reads** from YouTube's API: your Watch Later entries (entry id, video id,
  title) and the playlist's video count.
- **Network:** only `POST https://www.youtube.com/youtubei/v1/browse` (listing)
  and `POST https://www.youtube.com/youtubei/v1/browse/edit_playlist`
  (removing), and only after you click. YouTube obviously sees these, from your
  account, the same way it sees you removing videos by hand. **Nothing is sent
  to any other server.** No analytics, no telemetry, no remote config.
- **Stores** in `chrome.storage.local`: the removed-videos list (video id +
  title for each removed video, up to 6,000, plus two timestamps) until you
  click **Forget list** or remove the extension. Nothing is stored in
  `chrome.storage.sync`, and no cookie or header value is ever stored.

## What it does not do

- Does not touch any playlist other than Watch Later (`WL` is hard-coded), and
  does not like, subscribe, comment, or change settings.
- Does nothing until you click **Clear Watch Later** and confirm. Opening the
  popup makes one read-only request for the count.
- Does not send your cookies or the signed header anywhere but
  `www.youtube.com`, and does not keep them.
- Does not inject any UI into YouTube; everything you interact with is in the
  popup.
- Does not load code from anywhere.

## Honest caveats

- **This uses YouTube's private web API.** It is the same one YouTube's own
  page uses, but it is undocumented and can change without notice. If
  YouTube changes the request shape or the signing scheme, the extension will
  stop with an error rather than guess; [`innertube.js`](innertube.js) is the
  one file to update.
- **Removals can't be undone in bulk.** YouTube has no undo. The downloadable
  list is your safety net; download it before you **Forget** it.
- **Batch size 500 is what was tested.** It may also be close to a limit
  YouTube enforces silently; the split-in-half fallback covers a rejected
  batch, but a future YouTube change could make large batches fail outright.
- **It acts as whichever account the tab is signed in as.** Check the avatar
  first. Brand accounts should work (it sends the same page-id header YouTube's
  page does for them) but only a personal account has been tested.
- Reading the sign-in cookie is the trade-off for speed (see *Signing the
  requests*). If you'd rather an extension never see it, use YouTube's
  **Remove watched videos** for the watched ones and the ⋮ menu for the rest.
- YouTube may rate-limit an account that does this a lot. The extension backs
  off and retries, then stops with an error; wait a while and run it again,
  it picks up what's left.
- Only `www.youtube.com` in Chrome (or another Chromium browser that runs MV3
  extensions) is supported.

## Tests

From `chrome-extensions/`:

```
node tests/youtube-watch-later.test.mjs   # API helpers: config parsing, signing, paging, errors
node tests/owasp-audit.mjs                # static security audit of every extension here
```

## Security

Follows the shared [security guidelines](../SECURITY.md) (OWASP Browser
Extension Vulnerabilities Cheat Sheet): `storage`-only permission, HTTPS-only
top-frame content script, strict CSP, no `innerHTML`/`eval`, no remote code,
and `sender.id`-validated messaging with an allowlist of four message types
(`ytwl-status`, `ytwl-count`, `ytwl-start`, `ytwl-stop`). The popup renders
titles with `textContent` only, and the CSV export escapes quotes and prefixes
cells that start with `=`, `+`, `-` or `@` so a video title can't run as a
spreadsheet formula. The one network path is the same-origin API described
above. Enforced by `npm test` (`../tests/owasp-audit.mjs`).

## Files

| File | Purpose |
|------|---------|
| `manifest.json` | MV3 manifest, content script + popup |
| `innertube.js` | YouTube API helpers: read page settings, sign requests, parse playlist pages, build removal requests. No DOM, no network of its own |
| `content.js` | The worker: lists, removes in batches, retries, keeps the removed list, answers the popup |
| `popup.html` / `popup.css` / `popup.js` | Count, confirm, progress, stop, removed-list download |
