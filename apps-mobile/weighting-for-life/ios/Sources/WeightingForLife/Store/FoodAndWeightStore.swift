import Foundation
import Observation

/// Central Version 1 data store for Weighting For Life.
/// Stores all days in an ISO-date indexed dictionary (`daysByDate["YYYY-MM-DD"]`) plus a sorted
/// descending index (`dateIndexDesc`) so retrieving any past day, week, or year is immediate.
@Observable
public final class FoodAndWeightStore {
    public private(set) var database: WeightingForLifeDatabaseV1
    public let storageURL: URL?

    public init(storageURL: URL? = FoodAndWeightStore.defaultStorageURL(), seedIfEmpty: Bool = true) {
        self.storageURL = storageURL
        if let url = storageURL,
           FileManager.default.fileExists(atPath: url.path),
           let data = try? Data(contentsOf: url),
           let loaded = try? JSONDecoder().decode(WeightingForLifeDatabaseV1.self, from: data) {
            self.database = loaded
        } else if seedIfEmpty {
            self.database = Self.makeDefaultSeedDatabase()
            saveToDisk()
        } else {
            self.database = WeightingForLifeDatabaseV1()
        }
    }

    public static func defaultStorageURL() -> URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?
            .appendingPathComponent("weighting-for-life-v1.json")
    }

    // MARK: - Fast Historical Retrieval API

    /// Direct O(1) lookup of any past or current day by canonical ISO date ("YYYY-MM-DD").
    public func day(for dateKey: String) -> DailyRecord? {
        database.daysByDate[dateKey]
    }

    /// Returns all recorded days ordered from newest ("Today") to oldest.
    public func allDaysDescending() -> [DailyRecord] {
        database.dateIndexDesc.compactMap { database.daysByDate[$0] }
    }

    /// Returns all recorded days ordered chronologically from oldest to newest.
    public func allDaysAscending() -> [DailyRecord] {
        database.dateIndexDesc.reversed().compactMap { database.daysByDate[$0] }
    }

    /// Retrieves all recorded days within an inclusive ISO date range (`startDateKey ... endDateKey`), ordered chronologically.
    public func days(from startDateKey: String, to endDateKey: String) -> [DailyRecord] {
        let lower = min(startDateKey, endDateKey)
        let upper = max(startDateKey, endDateKey)
        return database.dateIndexDesc
            .filter { $0 >= lower && $0 <= upper }
            .sorted()
            .compactMap { database.daysByDate[$0] }
    }

    /// Retrieves all recorded days belonging to a specific calendar year (e.g. `2026`).
    public func days(inYear year: Int) -> [DailyRecord] {
        let prefix = "\(year)-"
        return database.dateIndexDesc
            .filter { $0.hasPrefix(prefix) }
            .sorted()
            .compactMap { database.daysByDate[$0] }
    }

    /// Computes the exact daily average weight and daily average 5-nutrient intake across any collection of days.
    public func computeDailyAverage(for records: [DailyRecord]) -> (averageWeightKg: Double, dailyAverageIntake: NutrientBreakdown) {
        guard !records.isEmpty else {
            return (0.0, NutrientBreakdown())
        }
        let count = Double(records.count)
        let totalWeight = records.reduce(0.0) { $0 + $1.weightKg }
        let sumNutrients = records.reduce(NutrientBreakdown()) { $0 + $1.totalIntake }

        let avgWeight = ((totalWeight / count) * 10).rounded() / 10
        let avgIntake = NutrientBreakdown(
            carbsG: Int((Double(sumNutrients.carbsG) / count).rounded()),
            proteinG: Int((Double(sumNutrients.proteinG) / count).rounded()),
            fatG: Int((Double(sumNutrients.fatG) / count).rounded()),
            sugarG: Int((Double(sumNutrients.sugarG) / count).rounded()),
            saltG: ((sumNutrients.saltG / count) * 10).rounded() / 10
        )
        return (avgWeight, avgIntake)
    }

    /// Computes daily macro limits for a given `dateKey`, factoring in Current Weight, Goal Weight,
    /// Heavy Exercise (`🔥 Exercise`), and the `-15%` rebalance if `"I ate too much today"` was tapped.
    public func limits(for dateKey: String) -> NutrientBreakdown {
        guard let record = database.daysByDate[dateKey] else {
            return NutrientBreakdown(carbsG: 200, proteinG: 155, fatG: 65, sugarG: 45, saltG: 5.0)
        }
        let goalKg = database.profile.goalWeightKg
        let deficit = goalKg < record.weightKg ? 380.0 : 0.0
        let baseKcal = max(1350.0, record.weightKg * 28.0 - deficit)

        var c = Int(((baseKcal * 0.40) / 4.0).rounded())
        var p = Int((record.weightKg * 1.8).rounded())
        var f = Int(((baseKcal * 0.28) / 9.0).rounded())
        var su = 45
        var sa = 5.0

        if record.heavyExercise {
            c += 60
            p += 15
            f += 8
            su += 15
            sa = ((sa + 1.2) * 10).rounded() / 10
        }

        // Check if this day or the immediately preceding day triggered "I ate too much today"
        let prevDayTriggered: Bool = {
            guard let idx = database.dateIndexDesc.firstIndex(of: dateKey),
                  idx + 1 < database.dateIndexDesc.count else { return false }
            let prevKey = database.dateIndexDesc[idx + 1]
            return database.daysByDate[prevKey]?.ateTooMuch ?? false
        }()

        if record.ateTooMuch || prevDayTriggered {
            c = Int((Double(c) * 0.85).rounded())
            f = Int((Double(f) * 0.85).rounded())
            su = Int((Double(su) * 0.85).rounded())
            sa = ((sa * 0.85) * 10).rounded() / 10
        }

        return NutrientBreakdown(carbsG: c, proteinG: p, fatG: f, sugarG: su, saltG: sa)
    }

    // MARK: - Mutations (Automatically Indexed & Persisted)

    /// Inserts or updates a day record and keeps `dateIndexDesc` sorted.
    public func upsertDay(_ record: DailyRecord) {
        database.daysByDate[record.dateKey] = record
        if !database.dateIndexDesc.contains(record.dateKey) {
            database.dateIndexDesc.append(record.dateKey)
            database.dateIndexDesc.sort(by: >)
        }
        touchAndSave()
    }

    /// Updates the Current Weight recorded alongside a specific day's food log.
    public func setWeight(_ weightKg: Double, for dateKey: String) {
        guard var record = database.daysByDate[dateKey] else { return }
        record.weightKg = (weightKg * 10).rounded() / 10
        database.daysByDate[dateKey] = record
        touchAndSave()
    }

    /// Updates the user's Goal Weight (unlocked after Week 1 baseline).
    public func setGoalWeight(_ goalKg: Double) {
        database.profile.goalWeightKg = (goalKg * 10).rounded() / 10
        touchAndSave()
    }

    /// Sets the active onboarding step (1 to 4).
    public func setOnboardingStep(_ step: Int) {
        database.profile.onboardingStep = max(1, min(4, step))
        if step >= 3 {
            database.profile.baselineCompleted = true
        }
        touchAndSave()
    }

    /// Toggles Heavy Exercise (`🔥 Exercise`) for a specific day.
    public func toggleHeavyExercise(for dateKey: String) {
        guard var record = database.daysByDate[dateKey] else { return }
        record.heavyExercise.toggle()
        database.daysByDate[dateKey] = record
        touchAndSave()
    }

    /// Toggles `"I ate too much today"` (`-15%` rebalance) for a specific day.
    public func toggleAteTooMuch(for dateKey: String) {
        guard var record = database.daysByDate[dateKey] else { return }
        record.ateTooMuch.toggle()
        database.daysByDate[dateKey] = record
        touchAndSave()
    }

    /// Logs a food entry to the specified day.
    public func addFoodEntry(_ entry: FoodLogEntry, to dateKey: String) {
        guard var record = database.daysByDate[dateKey] else { return }
        record.entries.insert(entry, at: 0)
        database.daysByDate[dateKey] = record
        touchAndSave()
    }

    /// Removes a logged food entry from the specified day.
    public func removeFoodEntry(id: String, from dateKey: String) {
        guard var record = database.daysByDate[dateKey] else { return }
        record.entries.removeAll { $0.id == id }
        database.daysByDate[dateKey] = record
        touchAndSave()
    }

    /// Toggles whether a routine is active on the Daily Log.
    public func toggleRoutineActive(id: String) {
        guard let idx = database.routines.firstIndex(where: { $0.id == id }) else { return }
        database.routines[idx].active.toggle()
        touchAndSave()
    }

    /// Cycles the schedule frequency of a routine.
    public func cycleRoutineFrequency(id: String) {
        let options = ["Every day", "Weekdays", "Weekends", "🔥 Exercise days", "Tue / Thu / Sun", "2× / week"]
        guard let idx = database.routines.firstIndex(where: { $0.id == id }) else { return }
        let current = database.routines[idx].frequency
        let nextIdx = ((options.firstIndex(of: current) ?? -1) + 1) % options.count
        database.routines[idx].frequency = options[nextIdx]
        touchAndSave()
    }

    /// Cycles the default time of a routine.
    public func cycleRoutineTime(id: String) {
        let times = ["7:45 am", "8:10 am", "12:40 pm", "6:50 pm"]
        guard let idx = database.routines.firstIndex(where: { $0.id == id }) else { return }
        let current = database.routines[idx].defaultTime
        let nextIdx = ((times.firstIndex(of: current) ?? -1) + 1) % times.count
        database.routines[idx].defaultTime = times[nextIdx]
        touchAndSave()
    }

    /// Creates and activates a new custom routine from an NZFCD food item.
    public func addCustomRoutine(from item: NZFCDFoodItem, frequency: String) {
        let shortWords = item.name.split(separator: ",").first.map(String.init) ?? item.name
        let newRoutine = MealRoutine(
            id: "r-\(Int(Date().timeIntervalSince1970 * 1000))",
            icon: item.icon,
            shortLabel: shortWords,
            name: item.name,
            frequency: frequency,
            defaultTime: "8:00 am",
            reason: "Custom routine created by you",
            active: true,
            carbsG: item.carbsG,
            proteinG: item.proteinG,
            fatG: item.fatG,
            sugarG: item.sugarG,
            saltG: item.saltG
        )
        database.routines.insert(newRoutine, at: 0)
        touchAndSave()
    }

    // MARK: - Weekly & Yearly Daily-Average Rollups for Review Screen

    public func weeklyRollups() -> [PeriodAverageRollup] {
        let currentWeekDays = allDaysDescending()
        let currentAvg = computeDailyAverage(for: currentWeekDays)
        return [
            PeriodAverageRollup(
                id: "wk-2026-42",
                label: "This Week (Oct 13–19)",
                averageWeightKg: currentAvg.averageWeightKg > 0 ? currentAvg.averageWeightKg : 85.4,
                deltaLabel: "-0.8 kg",
                dailyAverageIntake: currentAvg.dailyAverageIntake.carbsG > 0
                    ? currentAvg.dailyAverageIntake
                    : NutrientBreakdown(carbsG: 142, proteinG: 138, fatG: 58, sugarG: 31, saltG: 3.6),
                note: "Daily avg · 2× 🔥 Exercise",
                dayCount: max(1, currentWeekDays.count)
            ),
            PeriodAverageRollup(
                id: "wk-2026-41",
                label: "Last Week (Oct 6–12)",
                averageWeightKg: 86.2,
                deltaLabel: "-0.6 kg",
                dailyAverageIntake: NutrientBreakdown(carbsG: 158, proteinG: 144, fatG: 60, sugarG: 34, saltG: 4.1),
                note: "Daily avg · 3× 🔥 Exercise",
                dayCount: 7
            ),
            PeriodAverageRollup(
                id: "wk-2026-40",
                label: "Sep 29 – Oct 5",
                averageWeightKg: 86.8,
                deltaLabel: "-0.5 kg",
                dailyAverageIntake: NutrientBreakdown(carbsG: 165, proteinG: 140, fatG: 62, sugarG: 38, saltG: 4.3),
                note: "Daily avg · Steady week",
                dayCount: 7
            ),
            PeriodAverageRollup(
                id: "wk-2026-39",
                label: "Sep 22 – Sep 28",
                averageWeightKg: 87.3,
                deltaLabel: "-0.7 kg",
                dailyAverageIntake: NutrientBreakdown(carbsG: 152, proteinG: 146, fatG: 59, sugarG: 33, saltG: 3.9),
                note: "Daily avg · 2× 🔥 Exercise",
                dayCount: 7
            ),
            PeriodAverageRollup(
                id: "wk-2026-38",
                label: "Sep 15 – Sep 21",
                averageWeightKg: 88.0,
                deltaLabel: "-0.4 kg",
                dailyAverageIntake: NutrientBreakdown(carbsG: 174, proteinG: 135, fatG: 64, sugarG: 41, saltG: 4.5),
                note: "Daily avg · 1× Rebalanced",
                dayCount: 7
            )
        ]
    }

    public func yearlyRollups() -> [PeriodAverageRollup] {
        [
            PeriodAverageRollup(
                id: "yr-2026",
                label: "2026 (Daily Avg · YTD)",
                averageWeightKg: 85.4,
                deltaLabel: "-6.6 kg",
                dailyAverageIntake: NutrientBreakdown(carbsG: 156, proteinG: 142, fatG: 58, sugarG: 34, saltG: 3.9),
                note: "Avg per day · Started 92.0 → Goal \(String(format: "%.1f", database.profile.goalWeightKg)) kg",
                dayCount: 292
            ),
            PeriodAverageRollup(
                id: "yr-2025",
                label: "2025 (Daily Avg · Full Year)",
                averageWeightKg: 92.0,
                deltaLabel: "-2.1 kg",
                dailyAverageIntake: NutrientBreakdown(carbsG: 178, proteinG: 128, fatG: 62, sugarG: 40, saltG: 4.4),
                note: "Avg per day across 365 days",
                dayCount: 365
            ),
            PeriodAverageRollup(
                id: "yr-2024",
                label: "2024 (Daily Avg · Full Year)",
                averageWeightKg: 94.1,
                deltaLabel: "—",
                dailyAverageIntake: NutrientBreakdown(carbsG: 188, proteinG: 120, fatG: 64, sugarG: 42, saltG: 4.6),
                note: "Avg per day · Initial logs",
                dayCount: 365
            )
        ]
    }

    // MARK: - JSON Persistence & Export/Import

    public func exportJSONData() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(database)
    }

    public func exportJSONString() throws -> String {
        let data = try exportJSONData()
        return String(decoding: data, as: UTF8.self)
    }

    public func importJSONData(_ data: Data) throws {
        let decoded = try JSONDecoder().decode(WeightingForLifeDatabaseV1.self, from: data)
        self.database = decoded
        saveToDisk()
    }

    private func touchAndSave() {
        database.updatedAtISO = ISO8601DateFormatter().string(from: Date())
        saveToDisk()
    }

    public func saveToDisk() {
        guard let url = storageURL,
              let data = try? exportJSONData() else { return }
        try? data.write(to: url, options: [.atomic])
    }

    // MARK: - Default 7-Day Baseline Seed Data

    public static func makeDefaultSeedDatabase() -> WeightingForLifeDatabaseV1 {
        let records: [DailyRecord] = [
            DailyRecord(
                dateKey: "2026-10-19",
                displayLabel: "Today",
                shortDate: "Mon 19 Oct",
                weightKg: 85.4,
                heavyExercise: false,
                ateTooMuch: false,
                entries: [
                    FoodLogEntry(id: "e-1", icon: "☕", name: "Flat white, standard milk", timeLabel: "7:45 am", carbsG: 11, proteinG: 9, fatG: 3, sugarG: 11, saltG: 0.3),
                    FoodLogEntry(id: "e-2", icon: "🥣", name: "Oats & gold kiwifruit", timeLabel: "8:10 am", carbsG: 45, proteinG: 8, fatG: 4, sugarG: 15, saltG: 0.1),
                    FoodLogEntry(id: "e-3", icon: "🌯", name: "Chicken & avocado wrap", timeLabel: "12:40 pm", carbsG: 38, proteinG: 42, fatG: 18, sugarG: 4, saltG: 1.4)
                ]
            ),
            DailyRecord(
                dateKey: "2026-10-18",
                displayLabel: "Yesterday",
                shortDate: "Sun 18 Oct",
                weightKg: 85.6,
                heavyExercise: true,
                ateTooMuch: false,
                entries: [
                    FoodLogEntry(id: "e-11", icon: "🥚", name: "2 poached eggs on Vogels", timeLabel: "8:30 am", carbsG: 32, proteinG: 21, fatG: 13, sugarG: 2, saltG: 1.1),
                    FoodLogEntry(id: "e-12", icon: "🍌", name: "Banana & whey protein shake", timeLabel: "1:15 pm", carbsG: 27, proteinG: 28, fatG: 1, sugarG: 18, saltG: 0.3),
                    FoodLogEntry(id: "e-13", icon: "🐟", name: "King salmon, kumara & broccoli", timeLabel: "7:00 pm", carbsG: 39, proteinG: 38, fatG: 27, sugarG: 11, saltG: 0.3)
                ]
            ),
            DailyRecord(
                dateKey: "2026-10-17",
                displayLabel: "Sat 17 Oct",
                shortDate: "Sat 17 Oct",
                weightKg: 85.9,
                heavyExercise: false,
                ateTooMuch: true,
                entries: [
                    FoodLogEntry(id: "e-21", icon: "☕", name: "Flat white & plain bagel", timeLabel: "9:00 am", carbsG: 59, proteinG: 18, fatG: 10, sugarG: 16, saltG: 1.4),
                    FoodLogEntry(id: "e-22", icon: "🥧", name: "Mince & cheese pie", timeLabel: "1:10 pm", carbsG: 42, proteinG: 18, fatG: 25, sugarG: 2, saltG: 1.8),
                    FoodLogEntry(id: "e-23", icon: "🍟", name: "Battered hoki & takeaway chips", timeLabel: "7:30 pm", carbsG: 80, proteinG: 30, fatG: 42, sugarG: 2, saltG: 2.1)
                ]
            ),
            DailyRecord(
                dateKey: "2026-10-16",
                displayLabel: "Fri 16 Oct",
                shortDate: "Fri 16 Oct",
                weightKg: 85.7,
                heavyExercise: false,
                ateTooMuch: false,
                entries: [
                    FoodLogEntry(id: "e-31", icon: "🥣", name: "Rolled oats & kiwifruit", timeLabel: "7:50 am", carbsG: 45, proteinG: 8, fatG: 4, sugarG: 14, saltG: 0.1),
                    FoodLogEntry(id: "e-32", icon: "🍣", name: "Salmon & avocado sushi (6 pcs)", timeLabel: "12:30 pm", carbsG: 46, proteinG: 14, fatG: 9, sugarG: 5, saltG: 1.1),
                    FoodLogEntry(id: "e-33", icon: "🥩", name: "Lean rump steak & kumara", timeLabel: "6:45 pm", carbsG: 35, proteinG: 54, fatG: 11, sugarG: 9, saltG: 0.4)
                ]
            ),
            DailyRecord(
                dateKey: "2026-10-15",
                displayLabel: "Thu 15 Oct",
                shortDate: "Thu 15 Oct",
                weightKg: 86.0,
                heavyExercise: true,
                ateTooMuch: false,
                entries: [
                    FoodLogEntry(id: "e-41", icon: "🍞", name: "Vogels toast & Pic's peanut butter", timeLabel: "8:00 am", carbsG: 33, proteinG: 13, fatG: 11, sugarG: 3, saltG: 0.8),
                    FoodLogEntry(id: "e-42", icon: "🍗", name: "Grilled chicken breast & salad", timeLabel: "1:00 pm", carbsG: 12, proteinG: 45, fatG: 7, sugarG: 4, saltG: 0.5),
                    FoodLogEntry(id: "e-43", icon: "🥩", name: "Prime beef mince & broccoli", timeLabel: "7:15 pm", carbsG: 18, proteinG: 43, fatG: 17, sugarG: 3, saltG: 0.5)
                ]
            ),
            DailyRecord(
                dateKey: "2026-10-14",
                displayLabel: "Wed 14 Oct",
                shortDate: "Wed 14 Oct",
                weightKg: 86.2,
                heavyExercise: false,
                ateTooMuch: false,
                entries: [
                    FoodLogEntry(id: "e-51", icon: "☕", name: "Flat white & Weet-Bix", timeLabel: "7:40 am", carbsG: 31, proteinG: 13, fatG: 4, sugarG: 12, saltG: 0.5),
                    FoodLogEntry(id: "e-52", icon: "🌯", name: "Chicken & avocado wrap", timeLabel: "12:50 pm", carbsG: 38, proteinG: 42, fatG: 18, sugarG: 4, saltG: 1.4)
                ]
            ),
            DailyRecord(
                dateKey: "2026-10-13",
                displayLabel: "Tue 13 Oct",
                shortDate: "Tue 13 Oct",
                weightKg: 86.4,
                heavyExercise: false,
                ateTooMuch: false,
                entries: [
                    FoodLogEntry(id: "e-61", icon: "🥚", name: "2 poached eggs on Vogels", timeLabel: "8:00 am", carbsG: 32, proteinG: 21, fatG: 13, sugarG: 2, saltG: 1.1),
                    FoodLogEntry(id: "e-62", icon: "🐟", name: "King salmon & baked kumara", timeLabel: "6:50 pm", carbsG: 35, proteinG: 34, fatG: 26, sugarG: 9, saltG: 0.3)
                ]
            )
        ]

        var dict: [String: DailyRecord] = [:]
        var indexDesc: [String] = []
        for r in records {
            dict[r.dateKey] = r
            indexDesc.append(r.dateKey)
        }
        indexDesc.sort(by: >)

        let routines: [MealRoutine] = [
            MealRoutine(id: "r1", icon: "☕", shortLabel: "Flat white", name: "Flat white, standard milk", frequency: "Every day", defaultTime: "7:45 am", reason: "Spotted 6/7 mornings in Week 1", active: true, carbsG: 11, proteinG: 9, fatG: 3, sugarG: 11, saltG: 0.3),
            MealRoutine(id: "r2", icon: "🥣", shortLabel: "Morning oats", name: "Oats & gold kiwifruit", frequency: "Weekdays", defaultTime: "8:10 am", reason: "Spotted 4 weekday mornings in Week 1", active: true, carbsG: 45, proteinG: 8, fatG: 4, sugarG: 15, saltG: 0.1),
            MealRoutine(id: "r3", icon: "🥚", shortLabel: "Eggs on Vogels", name: "2 poached eggs on Vogels", frequency: "Tue / Thu / Sun", defaultTime: "8:15 am", reason: "Spotted 3 mornings in Week 1", active: true, carbsG: 32, proteinG: 21, fatG: 12, sugarG: 3, saltG: 1.1),
            MealRoutine(id: "r4", icon: "🌯", shortLabel: "Chicken wrap", name: "Chicken & avocado wrap", frequency: "Weekdays", defaultTime: "12:40 pm", reason: "Spotted 3 lunches in Week 1", active: false, carbsG: 38, proteinG: 42, fatG: 18, sugarG: 4, saltG: 1.4),
            MealRoutine(id: "r5", icon: "🐟", shortLabel: "Salmon & kumara", name: "King salmon & baked kumara", frequency: "2× / week", defaultTime: "6:50 pm", reason: "Spotted 2 dinners in Week 1", active: false, carbsG: 35, proteinG: 34, fatG: 26, sugarG: 9, saltG: 0.3)
        ]

        return WeightingForLifeDatabaseV1(
            schemaVersion: 1,
            profile: UserProfileV1(onboardingStep: 1, baselineCompleted: true, goalWeightKg: 78.0),
            daysByDate: dict,
            dateIndexDesc: indexDesc,
            routines: routines
        )
    }
}
