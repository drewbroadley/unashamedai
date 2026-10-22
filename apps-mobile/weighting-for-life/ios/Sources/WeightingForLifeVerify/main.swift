import Foundation
import WeightingForLifeCore

@main
struct WeightingForLifeVerify {
    static func check(_ condition: @autoclosure () -> Bool, _ message: String) {
        if !condition() {
            fputs("❌ FAILED: \(message)\n", stderr)
            exit(1)
        }
    }

    static func main() throws {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("wfl-verify-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let store = FoodAndWeightStore(storageURL: tempURL, seedIfEmpty: true)

        // 1. O(1) retrieval of past days by canonical ISO dateKey ("YYYY-MM-DD")
        let today = store.day(for: "2026-10-19")
        let yesterday = store.day(for: "2026-10-18")
        let saturday = store.day(for: "2026-10-17")

        check(today?.displayLabel == "Today", "Today display label")
        check(today?.weightKg == 85.4, "Today recorded weight")
        check(today?.totalIntake == NutrientBreakdown(carbsG: 94, proteinG: 59, fatG: 25, sugarG: 30, saltG: 1.8), "Today total intake")
        check(yesterday?.displayLabel == "Yesterday" && yesterday?.heavyExercise == true, "Yesterday exercise state")
        check(saturday?.ateTooMuch == true, "Saturday rebalance state")

        // 2. Date-range and year retrieval
        let range = store.days(from: "2026-10-14", to: "2026-10-17")
        check(range.map(\.dateKey) == ["2026-10-14", "2026-10-15", "2026-10-16", "2026-10-17"], "Date range query")

        let year2026 = store.days(inYear: 2026)
        check(year2026.count == 7, "Year 2026 query count")

        // 3. Persistence & JSON export/import round-trip
        store.setWeight(84.9, for: "2026-10-19")
        store.addFoodEntry(
            FoodLogEntry(icon: "🥝", name: "Zespri SunGold Kiwifruit", timeLabel: "3:00 pm", carbsG: 15, proteinG: 1, fatG: 0, sugarG: 13, saltG: 0.0),
            to: "2026-10-19"
        )

        let reloaded = FoodAndWeightStore(storageURL: tempURL, seedIfEmpty: false)
        check(reloaded.day(for: "2026-10-19")?.weightKg == 84.9, "Persisted weight reload")
        check(reloaded.day(for: "2026-10-19")?.totalIntake.carbsG == 109, "Persisted food entry reload")

        // 4. Daily averages for Weeks and Years rollups
        let avg = store.computeDailyAverage(for: store.allDaysDescending())
        check(avg.averageWeightKg > 80.0, "Computed daily average weight")
        check(store.weeklyRollups().count == 5, "Weekly rollups count")
        check(store.yearlyRollups().count == 3, "Yearly rollups count")

        // 5. Plain-English NZFCD autocomplete & search ranking across the full 2,904-item 2024 NZ FOODfiles database
        let engine = NZFCDSearchEngine()
        check(engine.catalog.count >= 2900, "Full NZFCD 2024 catalog loaded (\(engine.catalog.count) items)")
        check(engine.defaultSuggestions(limit: 10).count == 10, "Default suggestions count")
        check(!engine.search("e", limit: 10).isEmpty, "1-char autocomplete ('e')")
        check(!engine.search("p", limit: 10).isEmpty, "1-char autocomplete ('p')")
        let top10 = engine.search("poached egg", limit: 10)
        check(top10.count == 10, "Top 10 search count")
        check(top10.first?.item.name.lowercased().contains("poached") == true, "Top 1 match relevance")
        let top25 = engine.search("flat white", limit: 25)
        check(!top25.isEmpty && top25.first?.item.name.lowercased().contains("flat white") == true, "Flat white search")
        check(engine.search("rewena", limit: 5).first?.item.name.lowercased().contains("rewena") == true, "Rewena bread search")
        check(engine.search("feijoa", limit: 5).first?.item.name.lowercased().contains("feijoa") == true, "Feijoa search")
        check(engine.search("tim tam", limit: 5).first?.item.name.lowercased().contains("tim tam") == true, "Tim Tam search")
        check(engine.search("pavlova", limit: 5).first?.item.name.lowercased().contains("pavlova") == true, "Pavlova search")

        print("✅ WeightingForLifeCore V1 verified: \(engine.catalog.count) NZFCD foods loaded, O(1) dateKey lookup, range/year queries, JSON persistence, daily averages, and NZFCD search passed.")
    }
}
