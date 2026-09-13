# Kiwi Businesses Going Under

A data story on New Zealand company liquidations from 2005 to August 2026, by
year, sector and business size, told in Isotype-style pictograms with the warm,
white-space-heavy look of an airline in-flight magazine feature. Live at
[unashamedai.broadley.org.nz/nz-insolvency-since-gfc/](https://unashamedai.broadley.org.nz/nz-insolvency-since-gfc/).

## What it does

- A hero with a cloud of shopfront pictograms, three headline stats, then five
  magazine-style sections: year by year, who they are, how big they are, who
  sends them to court, and how this compares with 2009.
- **Year by year** counts every year's liquidations in shopfront pictograms,
  one symbol per 100 companies, with the crash years 2008–2010 and 2024–2026
  in coral. An expandable table carries the full Companies Office series:
  liquidations, receiverships, voluntary administrations, incorporations and
  removals.
- **Who they are** breaks the last twelve months down by sector using
  Centrix's Credit Indicator (one tool symbol = 50 companies) with an
  expandable table of counts, share of sector, year-on-year change, the
  "weight" (share of failures divided by share of businesses), and changes in
  credit demand and defaults.
- **How big they are** shows twenty people for the enterprise population by
  staff count and ten-person survival rows for firms born in 2020. No agency
  publishes liquidations by employee count; the page says so.
- **Who sends them to court** shows Inland Revenue's 70% share of 2025
  winding-up applications as ten gavels, plus the tax-debt figures and High
  Court registry counts.
- **Last time** lists the landmark collapses from Bridgecorp to Du Val.
- Sources and fine print sit in the footer. Hover any pictogram for its value.

## What it can touch

One static HTML file. No build step, no framework, no service worker, no
cookies, no `localStorage`.

- **Network:** exactly one outbound request, to Google Fonts
  (`fonts.googleapis.com` / `fonts.gstatic.com`) for Manrope. If that is blocked the page falls back to system fonts and works
  unchanged. Nothing else is fetched and nothing is sent anywhere.
- **Data:** every figure is embedded in a small object at the foot of the file
  (`NZI`), and the pictograms are drawn from eight inline SVG symbols. The page
  reads nothing from the visitor.

## What it does NOT do

No analytics, no tracking, no remote code, no storage, no forms. It is an
independent side project: it borrows the *mood* of an airline magazine (deep
teal, coral, rounded cards, a friendly bold sans) without any airline's name,
logo, koru or typeface, and says so in the footer. It is not a publication of
any government agency and does not use any agency's name or wordmark.

## Data and caveats

- Annual and monthly liquidation, receivership, voluntary administration,
  incorporation and removal counts are the Companies Office's published CSVs
  (calendar years; 2026 is January–August). They are revised when companies
  are restored to the register.
- Sector figures are Centrix's July 2026 Credit Indicator (rolling twelve
  months to June 2026). Centrix's transport liquidation count could not be read
  reliably from their chart and is omitted from Figure 2; its change and rating
  are in Table 2. Centrix counts differ slightly from the register.
- Business size comes from MBIE's 2025 Small Business Factsheet (Stats NZ
  Business Demography, February 2025). No official series reports insolvencies
  by employee count; section 3 describes the population at risk instead.
- Inland Revenue figures are from its 2024–25 annual report as reported by
  B2B News; court registry counts are McDonald Vague's.

## Updating it

All data lives in the `NZI` object in the last `<script>` block of
`index.html`: `years` rows are `[year, liquidations, receiverships,
voluntary administrations, incorporations, removals]`; `sectors` and
`survival` are self-describing. The pictograms and tables redraw from it.
Update the prose, the three headline stats and the "compiled" date in the
footer by hand.

## Credits

Built by Claude from public statistics, described by a human. Pictogram
language after Otto Neurath and Gerd Arntz.
