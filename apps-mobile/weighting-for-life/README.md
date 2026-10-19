# Weighting For Life (iOS Concept)

A stripped-back iOS food intake concept inspired by MacroFactor, built around five daily numbers — **Carbs**, **Protein**, **Fat**, **Sugar**, and **Salt** — backed by the [New Zealand Food Composition Database](https://www.foodcomposition.co.nz/).

Open [`index.html`](index.html) in any browser to try the interactive single-screen concept.

## Core design

1. **Week 1 Onboarding (Record 7 Days + Current Weight Before Goal Weight)** — when starting out, the app asks you to record **one week of normal eating and your current weight each day** *before* asking for a goal weight. From that first week, it learns your eating behaviours (e.g. daily morning flat white, weekday breakfast staples, weekend salt/fat spikes), unlocks **Goal Weight** selection anchored to your real baseline, and suggests 1-tap routines.
2. **Indicative Daily Intake strip (expandable on tap)** — five thin horizontal bars (`Carbs`, `Protein`, `Fat`, `Sugar`, `Salt`) sit at the top of the screen in their dedicated colours without turning red. Tap the strip only when you want to inspect the exact gram totals and limits.
3. **Plain-English search with ranked NZFCD matches (`foodcomposition.co.nz`)** — type a food in plain English and see the **top 10 or 25 closest matches** ordered from most relevant to least relevant, with a one-tap toggle between 10 and 25 items. Tap any match to log it at `Now` (or a selected date/time) with its icon and 5-nutrient breakdown.
4. **Suggested Routines & Routines Page** — repeated meals spotted during your Week 1 eating are offered as 1-tap routines (`☕ Flat white`, `🥣 Morning oats`, `🥚 Eggs on Vogels`), with a dedicated **Routines** page to accept suggestions, adjust schedules (`Every day`, `Weekdays`, `Weekends`, `🔥 Exercise days`), or create new routines.
5. **Today's weight recorded alongside the food log & Heavy Exercise days** — tap your weight pill (`⚖️ 85.4kg`) right beside `Normal` at the top to record your current weight for today (saved directly alongside that day's food log), or toggle `Normal` / `🔥 Exercise` to expand carb, protein, and salt allowances on heavy training days.
6. **"I ate too much today" button** — one tap at the bottom of the screen gently trims the next day's limits (`-15%` across carbs, fat, sugar, and salt while keeping protein steady) so tomorrow balances out without guilt.
7. **Review page (Days, Weeks, Years — Eating vs. Weight)** — step back through individual days using the top `< Today >` arrows, or tap **Review** to compare your recorded weight curve directly against your 5-nutrient intake across **Days**, **Weeks** (daily averages), and **Years** (daily averages).

## Data & privacy architecture (concept spec)

- **What it touches:** This directory currently contains a single-file interactive HTML concept (`index.html`) that runs locally in the browser with **zero network requests** and **zero external dependencies**.
- **Planned iOS storage:** Local `SwiftData` synced exclusively to the user's private iCloud container (`CloudKit` private database) — no sign-in, no account creation, no analytics, and no third-party servers.
- **NZFCD lookup:** Bundles the New Zealand Food Composition Database (`FOODfiles` / Concise Tables) on-device, converting reported sodium (`mg`) to salt (`g`) via $\text{Salt (g)} = \text{Sodium (mg)} \times 2.5 / 1000$.
