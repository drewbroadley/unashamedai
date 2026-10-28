# Leapmotor notes

Plain-English how-tos for the Leapmotor C10, written up from what other owners
have worked out. Live at
[unashamedai.broadley.org.nz/leapmotor/](https://unashamedai.broadley.org.nz/leapmotor/).

Unofficial. Not affiliated with, made by, or checked by Leapmotor.

## Pages

| Page | What it covers |
|------|----------------|
| [`index.html`](index.html) | The list of Leapmotor how-tos. |
| [`c10-change-wallpaper/`](c10-change-wallpaper/index.html) | Putting your own picture on the C10's centre-screen wallpaper, in 12 steps. |
| [`c10-soft-reset/`](c10-soft-reset/index.html) | Restarting the centre screen and driver's display from the steering wheel, in 5 steps. |
| [`c10-qdlink-iphone/`](c10-qdlink-iphone/index.html) | Mirroring an iPhone through QDLink, including where the car's Wi-Fi password is hidden, in 7 steps. |

### Change the wallpaper (C10)

The C10 has no setting for using your own picture as the background. If the
**AutoKit** app (the companion app for Carlinkit CarPlay / Android Auto adapters)
is installed on the car's screen, its *Advanced settings › OEM icon selection ›
+* button opens Android's file browser. From there, a picture on a USB stick can
be opened full screen and sent to Android's own wallpaper setter with
*⋮ › Set as… › Wallpaper*.

Each step has a drawn diagram of the screen with the thing to tap highlighted.
The diagrams are simplified drawings, not screenshots.

### Soft reset the screens (C10)

Holding the voice-command button (top right of the right-hand steering-wheel
spoke) and pushing in the left-hand spoke's scroll wheel for 20 to 30 seconds
restarts the centre screen and the driver's display without turning the car off.
Nothing is erased. Works on the EV and REEV.

The diagrams show a right-hand-drive steering wheel and dashboard, drawn, not
photographed. The page warns up front that it works while driving but turns the
driver-assist safety features and the speedometer off until the restart finishes.

### Get your iPhone onto QDLink (C10)

QDLink is Leapmotor's phone-mirroring app on the C10. An iPhone connects with
Apple's built-in Screen Mirroring over the car's Wi-Fi, and the Wi-Fi name and
password are on the last page of QDLink's help (the **?** in the top-right
corner, then swipe across to the iOS page). The page covers the car side (steps
1–4) and the iPhone side (Settings › Wi-Fi, then Control Center › Screen
Mirroring).

The car screens and iPhone screens are drawn, not screenshots, and network and
device names in them are placeholders.

## What the pages can touch

They are static HTML files. No build step, no framework, no service worker, no
cookies, no `localStorage`.

- **Network:** one outbound request, to Google Fonts (`fonts.googleapis.com` /
  `fonts.gstatic.com`) for Poppins and Lexend Deca. If it's blocked the pages
  fall back to system fonts and work unchanged. Source videos are plain links,
  **not embeds**, so nothing loads from YouTube unless you click one.
- **Link previews:** each guide's Open Graph and X tags point at its own
  `img/og-image.png`, a 1200×630 card built from the page's own drawings (the
  "Set as › Wallpaper" panel, the steering wheel with both buttons
  highlighted, and QDLink's iOS help page with the Wi-Fi details highlighted). Only link-preview services (Slack, LinkedIn, Facebook, iMessage
  and so on) fetch them; the pages themselves never load them. To rebuild them
  after changing a drawing or a card's wording, run
  `python3 scripts/leapmotor/render_og.py` (needs Google Chrome). It pastes each
  page's drawings into `scripts/leapmotor/og-card.html` and screenshots it.
- **Data:** none. The pages read nothing from you and send nothing anywhere.

## What they do NOT do

No analytics, no tracking, no remote code, no embeds, no storage.

## Caveats

- **There's no undo for the wallpaper change.** The owner who shared the method
  says getting Leapmotor's original wallpapers back takes "a reset" (as of May
  2026), without saying which kind. The page says this before the first step and
  suggests trying the harmless soft reset before a factory reset. Whether a soft
  reset is enough is not known.
- The wallpaper method comes from a single video filmed on a car set to Spanish. The menu
  names on the page are English translations and may not match an
  English-language screen word for word.
- It depends on AutoKit already being installed. The page doesn't cover
  installing AutoKit, and Leapmotor says the original C10 platform doesn't support
  CarPlay or Android Auto natively.
- A software update could close the wallpaper route or reset the wallpaper.
- The soft reset steps come from a single video by a New Zealand reviewer. The
  "If it doesn't work" tips on that page are general advice, not from the video.
- The QDLink steps come from the site author's own C10 rather than a video. The
  QDLink screens are drawn from description, so the real layout may differ in
  detail; the key facts (the **?** top right, the iOS page being the last help
  page, and it showing the Wi-Fi name and password) are first-hand.

## Credits

Method found by Telegram user Wallas 630 and demonstrated by Juanlu de Toledo in
a YouTube Short (Spanish, 3 May 2026):
<https://www.youtube.com/shorts/PACgZIGd1wI>. The page explains the steps in its
own words; it doesn't reproduce the video's transcript or frames.

Soft reset shown by Jerry Pan (Pan Motoring, Auckland) in a YouTube Short
(27 June 2025): <https://www.youtube.com/shorts/Uau1eR-xmrQ>. Same approach: own
words, drawn diagrams, no transcript or frames.

QDLink iPhone steps worked out by the site author on their own C10.

Built by Claude, described by a human.
