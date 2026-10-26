# Average Speed Cameras NZ

Every NZTA average speed safety camera site in New Zealand on one map: where
the first camera is, where the second one is, the stretch of road between them,
and how far apart they are. Live at
[unashamedai.broadley.org.nz/nz-average-speed-cameras/](https://unashamedai.broadley.org.nz/nz-average-speed-cameras/).

An average speed camera site is a pair (or a chain) of cameras. Your time from
one to the next gives your average speed, and you only get a notice if that
average is over the limit. NZTA publishes the sites in a
[web page](https://nzta.govt.nz/travelling-on-our-roads/safety-cameras/about-safety-cameras/fixed-safety-camera-locations/new-average-speed-safety-camera-sites)
and a long PDF book of GPS coordinates. This page puts the coordinates on a map.

It is a sibling of [Belmont & Kelson Roadworks](../sh2-belmont-kelson-roadworks/):
same look, same pan-and-zoom map, different data.

## What it does

- Opens on an overview of New Zealand with all 19 sites, coloured by status:
  enforcing, under construction or planned.
- Click a site (its dot or name on the map, in the list, or with the ‹ › buttons
  and arrow keys) to zoom to it. The map's dots are keyboard-focusable too. The section between the cameras is drawn along the actual road,
  with each camera marked A, B (C, D) as NZTA labels them, tagged **1st camera**
  and **2nd camera** in the direction of travel, and the distance between them
  on the line.
- **Reverse** swaps the direction, so the camera you reach first changes.
- The sidebar gives each camera's coordinates (with a link to OpenStreetMap),
  the surveyed detection points where NZTA has published them, the distance,
  the speed limit, the enforcement date, NZTA's before-and-after speed survey,
  and the deaths and serious injuries NZTA counted on that stretch.
- Neighbouring sections that fall inside the frame (Kahikatea Flat Road and
  Pine Valley Road; the two halves of Glenbrook Road) are shown faintly and are
  clickable.
- Each site has its own link: `#temarua`, `#matakana` and so on.
- Pan, wheel-zoom and pinch-zoom; keyboard focus works on the list. Light and
  dark themes follow your system setting.

## What it can touch

One static HTML file. No build step to view it, no framework, no service
worker, no cookies, no `localStorage`.

- **Network:** exactly one outbound request, to Google Fonts
  (`fonts.googleapis.com` / `fonts.gstatic.com`) for Barlow and Barlow
  Condensed. If that is blocked the page falls back to system fonts and works
  unchanged. Nothing else is fetched and nothing is sent anywhere. The links
  to NZTA's PDF and to OpenStreetMap are ordinary links; nothing loads from
  them until you click.
- **Link previews:** the page's Open Graph and X tags point at
  `img/og-image.png`, a 1200×630 card (Whitford Road with its 1st and 2nd
  camera and the distance, plus the site counts). Only link-preview services
  (Slack, LinkedIn, Facebook, iMessage and so on) fetch it; the page itself
  never loads it.
- **Data:** every site, every basemap (roads, rivers, lakes, coastline and
  place names around each section) and the New Zealand outline are embedded in
  the file. The page reads pointer position for pan, zoom and hover, and the
  `#site` part of the address so a link can open a site. Nothing else.

## What it does NOT do

No analytics, no tracking, no remote code, no storage, no map-tile requests to
a third party, no access to your location, clipboard or anything beyond the
page.

## Data and caveats

- **Camera positions, detection points, distances, survey and crash figures**
  are transcribed from NZTA's *Average speed camera information* book (October
  2026, v27). **Statuses and expected enforcement dates** are from NZTA's site
  list, last updated 13 October 2026. NZTA's region for SH6 Kingston to Five
  Rivers is Southland on the web page and Otago in the book; the page uses
  Southland.
- **Distances.** Where NZTA has surveyed the detection points (Kahikatea Flat
  Road, Pine Valley Road, Whitford Road, Matakana Road, SH2 Matatā, SH5
  Tumunui, SH2 Pōkeno), the page shows NZTA's distance between them. For SH26
  and SH1 Hunterville to Bulls it shows NZTA's figure, marked as not yet
  surveyed. Everywhere else NZTA still says "TBC", so the page shows the road
  distance between the two camera positions from OSRM routing over
  OpenStreetMap, marked with ≈. Where both exist they agree to within about 1%.
- **NZTA's own caveat:** detection points are gazetted in NZTM2000 and the book
  converts them to WGS84, so there may be small differences. The book is not
  the legal record, and neither is this page.
- **Te Mārua to Brown Owl.** NZTA's SH2 Hutt Valley roadworks emails of 2 and
  9 October 2026 said these cameras start operating on 21 October 2026, while
  the site list (13 October) still says under construction. The page shows the
  site list's status and notes the email.
- **Kaitaia–Awaroa Road and SH8 Lake Tekapo to Twizel** have four cameras each.
  The page gives the distance gap by gap and in total. NZTA's "stretch assessed"
  figure for Tekapo (30.5 km) is shorter than the road from Camera A to
  Camera D (about 51 km), and for Kingston (57.7 km) longer than A to B (about
  46 km); both figures are shown as NZTA gives them.
- **Whitford Road** shows 60 km/h, as on NZTA's camera page; the book's survey
  footnote says the limit has since gone up to 80 km/h, and the page says so.
- Street alignments, lakes, rivers, coastline and place names are from
  [OpenStreetMap](https://www.openstreetmap.org/) (© OpenStreetMap
  contributors, ODbL), simplified to within a few metres. The New Zealand
  outline on the overview is [Natural Earth](https://www.naturalearthdata.com/)
  1:10m (public domain).
- Signs on the road come first. NZTA installs "average speed camera area" signs
  before each section.

## Updating it

The `SITES` array in the second `<script>` block of `index.html` holds every
site, one per line, in the book's order. Each entry has the cameras as NZTA
lists them (`cams`, `[lat, lon]`), the surveyed detection points (`det`, or
`null` while NZTA says TBC), NZTA's distances in metres (`dist`, one per gap),
what lies at each end (`ends`), the status (`enforcing`, `construction` or
`planned`), and the facts shown in the sidebar.

- **NZTA publishes detection points for a site:** fill in `det` and `dist`.
  Nothing else needs rebuilding.
- **A status changes:** edit `status` and `expected`.
- **A new site, or a camera moves:** add or edit the entry, then rebuild the
  map data:

  ```bash
  python3 scripts/nz-average-speed-cameras/build_map.py
  ```

  It routes each section through its cameras with the public OSRM demo server,
  pulls a basemap for each site from the Overpass API and the New Zealand
  outline from the `world-atlas` package on jsDelivr, and rewrites the
  `const MAP=` line in `index.html`. It needs `curl` and Python 3, with no
  packages. Downloads are cached in `scripts/nz-average-speed-cameras/.cache/`
  (git-ignored), so only changed sites are fetched again. The Overpass server
  is often busy; the script retries until it answers.
- **The link-preview card** shows the status counts, so re-render it when a
  status changes:

  ```bash
  python3 scripts/nz-average-speed-cameras/render_og.py
  ```

  It fills `scripts/nz-average-speed-cameras/og-card.html` with the page's data
  and screenshots it with headless Google Chrome (set `CHROME` to the binary if
  it isn't in the usual macOS place). Pass a site id to feature a different
  section; the default is `whitford`.

## Credits

Built by Claude from NZTA's camera book, described by a human.
