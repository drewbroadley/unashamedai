# Weighting For Life — Version 1 (iOS & Web/PWA)

A stripped-back iOS & local web food intake tracker built around five daily numbers — **Carbs**, **Protein**, **Fat**, **Sugar**, and **Salt** — backed by the [New Zealand Food Composition Database](https://www.foodcomposition.co.nz/).

## What’s Included in Version 1

- **Interactive Web / Local PWA (`index.html`)** — Single-file offline-capable app with persistent ISO-date indexed storage (`localStorage['weighting-for-life:v1']`) and instant JSON export/inspection.
- **Native Swift / SwiftUI Core Package (`ios/`)** — Cross-platform iOS 17+ / macOS 14+ Swift Package (`WeightingForLifeCore` + `WeightingForLifeVerify`) implementing the indexed `FoodAndWeightStore`, `NZFCDSearchEngine`, bundled `nzfcd_v1.json` catalog, and SwiftUI views.

## Core Features

1. **Clean 4-Step Onboarding (`1. Setup (Wk 1)`)**:
   - **Step 1 (`1 · Week 1`)**: Record 7 days of normal eating plus your **Current Weight** each day while Goal Weight stays locked.
   - **Step 2 (`2 · Habits`)**: View eating behaviours spotted from Week 1 (`☕ Morning Flat White`, `🥚 High-Protein Breakfasts`, `🍟 Saturday Takeaway Spike`).
   - **Step 3 (`3 · Goal`)**: Unlock and set **Goal Weight** anchored to your Week 1 baseline with a semi-circular gauge and daily macro targets.
   - **Step 4 (`4 · Routines`)**: Turn repeated Week 1 meals into 1-tap shortcuts on your daily log.
2. **Indicative Daily Intake Strip**:
   - Five compact macro bars (`Carbs`, `Protein`, `Fat`, `Sugar`, `Salt`) in dedicated vibrant colours on pastel tracks that **never turn red** when approaching or exceeding 100%. Tap to expand exact gram totals vs. daily limits.
3. **Plain-English NZFCD Search (Top 10 / Top 25)**:
   - Type in plain English (e.g. `poached egg`, `vogels`, `flat white`, `pie`) to see the **Top 10 or Top 25 closest matches** ranked from most relevant to least relevant.
4. **Current Weight Recorded Alongside Food Log + Exercise & Next-Day Rebalance**:
   - Tap the single-line height-locked weight pill (`⚖️ 85.4kg`) beside `Normal` / `🔥 Exercise` to adjust today's **Current Weight** (`-0.1 / +0.1 kg` stepper + slider), saved directly inside that day's record.
   - Tap **`😮‍💨 I ate too much today`** at the bottom to gently trim the next day's limits (`-15%` across carbs, fat, sugar, and salt while keeping protein steady).
5. **Review Page (`Days | Weeks | Years` — Eating vs. Weight)**:
   - Compare your weight trend curve against your 5-nutrient intake across **Days**, **Weeks** (`Daily Average Intake`, `Avg · XX%`, `Avg XX.X kg`), and **Years** (`Daily Average Intake`, `Avg · XX%`, `Avg XX.X kg`).

## Data Storage & Fast Historical Retrieval (`schemaVersion: 1`)

All historical and current day records are stored in an **ISO-8601 date-indexed map (`daysByDate["YYYY-MM-DD"]`)** paired with a pre-sorted descending date index (`dateIndexDesc`):

```json
{
  "schemaVersion": 1,
  "updatedAtISO": "2026-10-20T00:00:00Z",
  "profile": {
    "onboardingStep": 1,
    "baselineCompleted": true,
    "goalWeightKg": 78.0
  },
  "daysByDate": {
    "2026-10-19": {
      "dateKey": "2026-10-19",
      "label": "Today",
      "shortDate": "Mon 19 Oct",
      "weightKg": 85.4,
      "heavyExercise": false,
      "ateTooMuch": false,
      "entries": [
        { "id": 1, "icon": "☕", "name": "Flat white, standard milk", "time": "7:45 am", "c": 11, "p": 9, "f": 3, "su": 11, "sa": 0.3 }
      ]
    }
  },
  "dateIndexDesc": ["2026-10-19", "2026-10-18", "2026-10-17"]
}
```

- **$O(1)$ Past Day Lookup**: Retrieve any specific date directly via `WFLStore.getDay("2026-10-18")` (Web) or `store.day(for: "2026-10-18")` (Swift).
- **Chronological Date-Range & Year Queries**: Pull any slice of past days via `WFLStore.getDaysInRange("2026-10-13", "2026-10-19")` / `store.days(from:to:)` or `store.days(inYear: 2026)`.
- **Daily Average Rollups**: `store.computeDailyAverage(for:)` computes the exact daily average weight and daily average 5-nutrient intake across any week, month, or year slice.

## Privacy, Permissions & Honest Caveats

- **What it touches**:
  - `index.html` reads and writes only to browser `localStorage` under the key `weighting-for-life:v1` (plus optional clipboard copy when you click **Export**).
  - The Swift package (`ios/`) reads the bundled `nzfcd_v1.json` resource and writes atomic JSON snapshots to the app's local `Documents/weighting-for-life-v1.json` file.
- **Zero network requests**: Neither the web app nor the Swift package makes any network requests, loads any external scripts/fonts, or sends data to any server.
- **What it does NOT do**: No accounts, no analytics, no telemetry, no third-party SDKs, and no cloud servers outside the user's own device / private iCloud container.
- **Caveats**:
  - Nutrient values in the bundled NZFCD subset (`47` common NZ foods) are per standard serving; custom gram-weight scaling and full raw `FOODfiles` import are not yet wired into the UI.
  - Salt (`g`) is derived from reported sodium (`mg`) using $\text{Salt (g)} = \text{Sodium (mg)} \times 2.5 / 1000$.
