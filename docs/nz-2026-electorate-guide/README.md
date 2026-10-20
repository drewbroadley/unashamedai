# Electorate vs Party: NZ 2026 Split-Vote & Electorate Guide

An interactive split-vote and candidate guide for the 7 November 2026 New Zealand
General Election, covering all **71 electorates** (64 General and 7 Māori
electorates), **481 candidates**, and **7 major parties**. Live at
[unashamedai.broadley.org.nz/nz-2026-electorate-guide/](https://unashamedai.broadley.org.nz/nz-2026-electorate-guide/).

## What it does

- Starts with a single fill-in-the-blanks sentence:
  > *“I am from `<city, town or suburb>` and I want to vote for `<local candidate>` and the `<political party>` party.”*
- Maps **220+ cities, towns, and suburbs** across New Zealand to their official
  **August 2025 Representation Commission Final Electorate Boundaries** for the
  2026 General Election (including newly formed and redrawn seats such as
  *Kāpiti*, *Kenepuru*, *Wellington North*, *Wellington Bays*, *Glendene*,
  *Henderson*, *Waitākere*, *Ōtāhuhu*, *Mt Maunganui*, and *East Cape*), then
  populates the exact candidates standing in that electorate.
- Once all three blanks are chosen, reveals a four-chapter breakdown tailored to
  that combination:
  1. **Your Ballot Verdict:** How your local candidate vote and national Party
     Vote interact under MMP seat allocation rules, official Vote.nz party list
     rankings, the "2-for-1" local MP effect, and the 1-electorate coat-tailing
     threshold.
  2. **Piece One — The Individuals:** Row-aligned side-by-side comparison of your
     chosen local candidate against your Party Vote's local candidate (or any
     other candidate in your electorate), covering career before 2023, actions
     during the 2023–2026 term, and 2026–2029 priorities, followed by a summary
     table of all candidates in the electorate and local policy clashes vs
     complementarities.
  3. **Piece Two — The Political Parties:** Row-aligned side-by-side comparison
     of your chosen Party Vote against your local candidate's party, pairing
     2026 platforms with historical promise-keeping scores from
     [Promised vs Performed](https://unashamedai.broadley.org.nz/nz-govt-promised-vs-did/).
  4. **Policy Coverage Across 8 Issues:** Side-by-side check across Tax &
     Economy, Cost of Living, Healthcare, Housing, Transport, Law & Order,
     Climate & Water, and Democracy & Te Tiriti showing where your two votes
     align, complement each other, or act as a check and balance.

## What it can touch

It is one static HTML file (`index.html`, 776 KB) with zero external network
dependencies.

- **Network: zero outbound requests.** All 71 electorates, 481 candidate
  profiles, 17 party list rankings, and 7 party platforms are embedded as JSON
  inside the file. System serif (`Iowan Old Style` / `Charter` / `Georgia`) and
  sans-serif (`Helvetica Neue`) fonts are used directly from the device.
- **Shareable URLs:** Selections are encoded in the URL query string
  (`?electorate=remutaka&party=top&cand=hipkins`) so any split-vote comparison
  can be bookmarked or shared directly.

## Sources

- **Representation Commission 2025 Final Report ([elections.nz](https://elections.nz)):**
  Official 2026 electorate boundaries and suburb/town allocations across all 64
  General and 7 Māori electorates.
- **Electoral Commission ([vote.nz](https://vote.nz)):** Official 2026 candidate
  nominations across all 71 electorates and 17 party lists.
- **Policy.nz ([policy.nz/2026](https://policy.nz/2026)):** Candidate
  biographies, statements, priorities, and party policy platforms.
- **Promised vs Performed ([unashamedai.broadley.org.nz/nz-govt-promised-vs-did/](https://unashamedai.broadley.org.nz/nz-govt-promised-vs-did/)):**
  2017–2026 government promise-keeping records.
