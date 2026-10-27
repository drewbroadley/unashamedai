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

### Change the wallpaper (C10)

The C10 has no setting for using your own picture as the background. If the
**AutoKit** app (the companion app for Carlinkit CarPlay / Android Auto adapters)
is installed on the car's screen, its *Advanced settings › OEM icon selection ›
+* button opens Android's file browser. From there, a picture on a USB stick can
be opened full screen and sent to Android's own wallpaper setter with
*⋮ › Set as… › Wallpaper*.

Each step has a drawn diagram of the screen with the thing to tap highlighted.
The diagrams are simplified drawings, not screenshots.

## What the pages can touch

They are static HTML files. No build step, no framework, no service worker, no
cookies, no `localStorage`.

- **Network:** one outbound request, to Google Fonts (`fonts.googleapis.com` /
  `fonts.gstatic.com`) for Poppins and Lexend Deca. If it's blocked the pages
  fall back to system fonts and work unchanged. The source video is a plain link,
  **not an embed**, so nothing loads from YouTube unless you click it.
- **Data:** none. The pages read nothing from you and send nothing anywhere.

## What they do NOT do

No analytics, no tracking, no remote code, no embeds, no storage.

## Caveats

- **There's no undo for the wallpaper change.** The owner who shared the method
  says getting Leapmotor's original wallpapers back needs a reset of the screen
  system (as of May 2026). The page says this before the first step.
- The method comes from a single video filmed on a car set to Spanish. The menu
  names on the page are English translations and may not match an
  English-language screen word for word.
- It depends on AutoKit already being installed. The page doesn't cover
  installing AutoKit, and Leapmotor says the original C10 platform doesn't support
  CarPlay or Android Auto natively.
- A software update could close this route or reset the wallpaper.

## Credits

Method found by Telegram user Wallas 630 and demonstrated by Juanlu de Toledo in
a YouTube Short (Spanish, 3 May 2026):
<https://www.youtube.com/shorts/PACgZIGd1wI>. The page explains the steps in its
own words; it doesn't reproduce the video's transcript or frames. Built by Claude,
described by a human.
