# Promised vs Performed

A delivery record of New Zealand's last two governments, built for the 7 November
2026 general election. Live at
[unashamedai.broadley.org.nz/nz-govt-promised-vs-did/](https://unashamedai.broadley.org.nz/nz-govt-promised-vs-did/).

## What it does

- Tracks **347 election and coalition promises** from five parties across two
  governments: Labour, the Greens and NZ First (October 2017 to November 2023),
  and National, ACT and NZ First (November 2023 to present).
- Scores each one on **delivery, not merit**. A promise kept is scored the same
  whether the policy worked or was a disaster, and a promise broken the same
  whether dropping it was cowardice or good sense. Seven outcomes: delivered,
  largely delivered, partly delivered, not delivered, abandoned, in progress,
  superseded.
- Every promise carries a link to **where the promise was made** (a manifesto or a
  signed coalition agreement) and at least one link to **evidence of what
  happened**. 573 distinct source links across 109 domains.
- Plots **21 official statistical series** from 2017 to 2026 alongside the
  promises: inflation, unemployment, house prices, rents, net migration, Crown
  debt, both child poverty measures, benefit numbers, emissions, road deaths,
  prison muster and more. Each chart shades who was in office, marks the Covid-19
  period, and shows the change during each government's own stretch separately.
- Filter by term, party, outcome, source type and promise kind; search across all
  347; expand any promise for what happened and its sources.

## The headline finding

Labour kept 55% of the promises it could be judged on. The National-led coalition
has kept 58%. On 347 promises, three points apart is a tie.

What separates them is not how much they kept but what they promised. 65% of the
current government's commitments come from signed coalition agreements, written
after the election by people who already knew what was deliverable, against 43% of
Labour's. Across the dataset, coalition-agreement commitments are kept 61% of the
time and manifesto pledges 51%. Promises to *do a thing* are kept 70% of the time
by anyone; promises to *hit a number*, 36%. The site's like-for-like column
reweights every party to the same mix so those effects can be separated from
performance.

## What it can touch

It is one static HTML file, 766 KB. No build step, no framework, no service
worker.

- **Network: zero outbound requests.** No fonts, no scripts, no stylesheets, no
  images, no analytics, no CDN. Every byte the page needs is in the file. All 347
  promises and all 21 statistical series are embedded as JSON in a `<script>` tag.
  It works with the network off. The only `https://` addresses in the file are
  links you can choose to click.
- **Storage: none.** No `localStorage`, no `sessionStorage`, no IndexedDB, no
  cookies. Filters and open sections live in a JavaScript variable and are gone
  when you close the tab.
- **Typography** uses the serif already on your machine (Charter or Iowan Old
  Style on macOS, Georgia elsewhere). Nothing is downloaded.

## What it does NOT do

No analytics, no tracking pixels, no remote code, no storage, no cookies, no
access to location, camera, clipboard, or anything beyond drawing the page. It
does not know you visited.

## Honest caveats

This is the part worth reading before you quote a number at anyone.

- **It scores delivery, not merit**, and it cannot tell you whether a government
  *caused* the outcomes on its watch. Most of the statistical series were already
  moving before the government took office. Inflation and interest rates in
  particular were driven by a global cycle that hit every comparable country.
- **The comparison is not symmetrical.** Labour governed for six years and one
  month, with Covid-19 taking over the agenda from 2020 to 2022, and held a
  single-party majority from 2020. The current government has governed for two
  years and nine months, its term is unfinished, and it needs two coalition
  partners to agree.
- **Unfinished promises count against the score.** Every in-progress promise in
  the dataset belongs to the current term, because the other government's ended in
  2023. Excluding them would hand the current government an exemption its
  predecessor could not use, worth roughly nine points.
- **70 of the 347 status calls are flagged as genuinely arguable.** Both readings
  are given on the promise. Disagree with them and the numbers move.
- **The Greens' figure is the least trustworthy on the site.** It rests on 33
  promises, 42% of them targets for things outside the party's control, and five of
  them pledges in portfolios the Greens never held in Cabinet.
- **Coalition commitments are co-signed but recorded against one party.** All 19
  broken signed-agreement commitments sit with ACT or NZ First, while National's
  own agreement list shows no outright failure. That is a bias by role, not by
  politics, and it is *not* corrected for.
- **Some 2017 and 2020 manifesto PDFs are no longer hosted anywhere reachable.**
  Those promises cite the strongest available record of the commitment instead.
- **It is one round of research, not a peer-reviewed audit.** Treat it as a
  starting point with its sources attached, not a final verdict.

## The data

The full dataset, every source link, the outcome series and the build scripts live
in their own repository:

- [**github.com/drewbroadley/nz-govt-2026-promised-vs-did**](https://github.com/drewbroadley/nz-govt-2026-promised-vs-did)
- [`data/promises.csv`](https://github.com/drewbroadley/nz-govt-2026-promised-vs-did/blob/main/data/promises.csv) — all 347 promises as a spreadsheet
- [`data/indicators.csv`](https://github.com/drewbroadley/nz-govt-2026-promised-vs-did/blob/main/data/indicators.csv) — the 21 series, one row per year
- [`sources/by-policy-area.md`](https://github.com/drewbroadley/nz-govt-2026-promised-vs-did/blob/main/sources/by-policy-area.md) — every promise with its links, grouped by subject
- [`METHODOLOGY.md`](https://github.com/drewbroadley/nz-govt-2026-promised-vs-did/blob/main/METHODOLOGY.md) — the scoring rules in full, including where they are weak

That repository is the canonical source. This page is a published copy of the same
build, so the data links point there rather than duplicating five megabytes of CSV
into this repo.

Released under CC0 1.0: a public domain dedication. Copy, adapt and republish any
of it, with no permission and no attribution required.

## Corrections

Every status call is a judgement. If you think one is wrong,
[open an issue](https://github.com/drewbroadley/nz-govt-2026-promised-vs-did/issues)
with a source, or email drew@broadley.org.nz. Corrections with a source attached
will be made. Arguments that a policy was good or bad will not change a status:
the site scores whether things happened, not whether they should have.
