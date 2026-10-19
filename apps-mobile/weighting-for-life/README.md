# Weighting For Life (iOS Concept)

A stripped-back iOS food intake concept inspired by MacroFactor, built around five daily numbers — **Carbs**, **Protein**, **Fat**, **Sugar**, and **Salt** — backed by the [New Zealand Food Composition Database](https://www.foodcomposition.co.nz/).

Open [`index.html`](index.html) in any browser to try the interactive single-screen concept.

## Core design

1. **Indicative Daily Intake strip (expandable on tap)** — five thin horizontal bars (`Carbs`, `Protein`, `Fat`, `Sugar`, `Salt`) sit at the top of the screen with no clutter. Tap the strip only when you want to inspect the exact gram totals and limits.
2. **Plain-English logging (`foodcomposition.co.nz`)** — type one or more foods in plain English (e.g. `"2 poached eggs on Vogels + flat white"`), pick a timestamp (`Now` by default, or tap to change date/time), and log each item with an icon and its 5-nutrient breakdown.
3. **Routines** — 1-tap chips for daily regulars (e.g. morning flat white, weekday oats).
4. **Weight trajectory & Heavy Exercise days** — set where you are (`86 kg`) and where you want to be (`78 kg`) to set regular daily limits, with a 1-tap `Normal` / `🔥 Exercise` toggle that expands carb, protein, and salt allowances on heavy training days.
5. **"I ate too much today" button** — one tap at the bottom of the screen gently trims tomorrow's limits (`-15%` across carbs, fat, sugar, and salt while keeping protein steady) so the next day balances out without guilt.

## Data & privacy architecture (concept spec)

- **What it touches:** This directory currently contains a single-file interactive HTML concept (`index.html`) that runs locally in the browser with **zero network requests** and **zero external dependencies**.
- **Planned iOS storage:** Local `SwiftData` synced exclusively to the user's private iCloud container (`CloudKit` private database) — no sign-in, no account creation, no analytics, and no third-party servers.
- **NZFCD lookup:** Bundles the New Zealand Food Composition Database (`FOODfiles` / Concise Tables) on-device, converting reported sodium (`mg`) to salt (`g`) via $\text{Salt (g)} = \text{Sodium (mg)} \times 2.5 / 1000$.
