# Belmont & Kelson Roadworks

An interactive map of NZTA's weekly "Wellington region state highway roadworks"
email, cut down to the part that matters if you live around Belmont Domain or
Kelson: State Highway 2 (Western Hutt Road) from Kelson south to the Dowse
interchange. Live at
[unashamedai.broadley.org.nz/sh2-belmont-kelson-roadworks/](https://unashamedai.broadley.org.nz/sh2-belmont-kelson-roadworks/).

The Wellington Transport Alliance emails every Friday afternoon with the coming
week's state highway roadworks for the whole region, Kāpiti to Wairarapa. Most of
it is somewhere else. This page keeps the SH2 Hutt Valley jobs between Kelson and
Dowse, draws them on the road, and lists the rest of SH2 and the regional notes
underneath.

It is a sibling of [Te Awa Kairangi Roadworks](../te-awa-kairangi-roadworks/),
which does the same for the Melling project's own email in the Lower Hutt CBD.
Same code, different email, different stretch of road.

## What it does

- Draws each SH2 job from the week's email along the actual carriageway (the
  southbound lanes are the eastern side, northbound the western), coloured by
  what is happening: road closed, night lane closure, traffic management.
- Marks Belmont Domain, Kennedy Good Bridge, the Melling intersection, the
  Normandale overbridge and the Dowse interchange, so "Owen Street to Kennedy
  Good Bridge" in the email is a place on a map, not a sentence.
- A **night-by-night strip** on every job (Sa Su Mo Tu We Th Fr) shows which
  nights of the roadworks week it runs.
- Click any line, pin or list entry for the email's wording, the hours, which
  direction it affects, and which email it came from.
- **Week selector** in the header steps between weekly emails, and **Changes
  this week** flags what is *new*, *updated* or *finished* since the previous one
  (both come alive once a second week is added).
- SH2 jobs further north (Upper Hutt, Te Marua, Kaitoke) and the regional notes
  (Remutaka Hill, the Urban Motorway closures, the Māoribank speed limit, speed
  cameras) are listed in the sidebar without a map location.
- Pan, wheel-zoom and pinch-zoom; keyboard focus works on the list.
- A link to subscribe to the SH2 Hutt Valley list at the bottom of the sidebar.

## What it can touch

One static HTML file. No build step, no framework, no service worker, no cookies,
no `localStorage`.

- **Network:** exactly one outbound request, to Google Fonts
  (`fonts.googleapis.com` / `fonts.gstatic.com`) for Barlow and Barlow Condensed.
  If that is blocked the page falls back to system fonts and works unchanged.
  Nothing else is fetched and nothing is sent anywhere. The subscribe link in the
  sidebar is an ordinary link to NZTA's Campaign Monitor form; nothing is loaded
  from it until you click.
- **Data:** the basemap (about 1,370 simplified street, rail, river and park
  shapes) and every week's roadworks list are embedded in the file. The page reads
  pointer position for pan/zoom and hover, and nothing else.

## What it does NOT do

No analytics, no tracking, no remote code, no storage, no map-tile requests to a
third party, no access to location, clipboard or anything beyond the page.

## Updating it each week

All the content lives in two arrays near the top of the second `<script>` block
in `index.html`:

- `SITES` — one entry per place, with a stable id, a display name, a category,
  an optional `dir` line (which direction of travel it affects) and its geometry
  (`line`, `lines`, `point` or `poly` in `[lat, lon]`). Sites with `geom: null`
  and `offmap: true` are listed under "Further north on SH2".
- `UPDATES` — one entry per weekly email: `week` (the Saturday the email's week
  starts), `emailDate`, the `items` (each `{ site, text, when, days }`, where
  `days` is the list of ISO dates the job runs and feeds the night strip), any
  `region` notes, and the email's weather caveat in `notes`.

To add a week: append a new object to `UPDATES` (add any new place to `SITES`
first). The page diffs consecutive weeks itself, so "Changes this week" needs no
extra work. The SH2 line geometry for a new section can be sliced from the
`BASEMAP` ways named "Western Hutt Road" between two latitudes.

## Data and caveats

- Roadworks content is transcribed from the NZTA Wellington Transport Alliance
  "Wellington region state highway roadworks" email (18 September 2026, for the
  week of 19–25 September, at time of writing). Wording is kept close to the
  source; where the email names a street as a start or end point, the line runs
  to that street's junction with SH2.
- Street alignments are from [OpenStreetMap](https://www.openstreetmap.org/)
  (© OpenStreetMap contributors, ODbL), simplified to roughly 2–4 m. Belmont
  Domain is the OSM polygon tagged "Belmont Reserve", the sports ground between
  SH2 and the river just north of Kennedy Good Bridge.
- The Tuesday-night full southbound closure Melling → Dowse says "detour via local
  roads"; the email does not give the route, so none is drawn.
- The map is not a substitute for the on-site signage. Works are weather
  dependent and move at short notice; the email says so every week and so does
  the page.

## Signing up for the email

NZTA's [Sign up for roadworks updates](https://www.nzta.govt.nz/projects/sh-maintenance-programme/wellington-transport-alliance/roadworks-updates)
page has one list per corridor. The one this page reads is
[SH2 Hutt Valley](https://confirmsubscription.com/h/t/D234C038E802AAF0); it is
double opt-in, so confirm the email it sends you.

## Credits

Built by Claude from Drew's inbox, described by a human.
