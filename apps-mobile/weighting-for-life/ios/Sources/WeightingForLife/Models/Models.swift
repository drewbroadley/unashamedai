import Foundation

/// Five core daily nutrients tracked by Weighting For Life.
/// Note: Bars always keep their dedicated nutrient color (never turning red when approaching/exceeding limits).
public struct NutrientBreakdown: Codable, Sendable, Equatable {
    public var carbsG: Int
    public var proteinG: Int
    public var fatG: Int
    public var sugarG: Int
    public var saltG: Double

    public init(carbsG: Int = 0, proteinG: Int = 0, fatG: Int = 0, sugarG: Int = 0, saltG: Double = 0.0) {
        self.carbsG = carbsG
        self.proteinG = proteinG
        self.fatG = fatG
        self.sugarG = sugarG
        self.saltG = (saltG * 10).rounded() / 10
    }

    public static func + (lhs: NutrientBreakdown, rhs: NutrientBreakdown) -> NutrientBreakdown {
        NutrientBreakdown(
            carbsG: lhs.carbsG + rhs.carbsG,
            proteinG: lhs.proteinG + rhs.proteinG,
            fatG: lhs.fatG + rhs.fatG,
            sugarG: lhs.sugarG + rhs.sugarG,
            saltG: ((lhs.saltG + rhs.saltG) * 10).rounded() / 10
        )
    }

    /// Converts NZFCD Sodium (mg) to Salt (g): Salt(g) = Sodium(mg) * 2.5 / 1000
    public static func saltGrams(fromSodiumMg sodiumMg: Double) -> Double {
        ((sodiumMg * 2.5 / 1000.0) * 10).rounded() / 10
    }
}

/// A single food item from the New Zealand Food Composition Database (NZFCD).
public struct NZFCDFoodItem: Codable, Sendable, Equatable, Identifiable {
    public var id: String
    public var icon: String
    public var name: String
    public var category: String
    public var carbsG: Int
    public var proteinG: Int
    public var fatG: Int
    public var sugarG: Int
    public var saltG: Double

    public var nutrients: NutrientBreakdown {
        NutrientBreakdown(carbsG: carbsG, proteinG: proteinG, fatG: fatG, sugarG: sugarG, saltG: saltG)
    }

    public init(
        id: String,
        icon: String,
        name: String,
        category: String,
        carbsG: Int,
        proteinG: Int,
        fatG: Int,
        sugarG: Int,
        saltG: Double
    ) {
        self.id = id
        self.icon = icon
        self.name = name
        self.category = category
        self.carbsG = carbsG
        self.proteinG = proteinG
        self.fatG = fatG
        self.sugarG = sugarG
        self.saltG = saltG
    }
}

/// A logged food entry inside a day's record.
public struct FoodLogEntry: Codable, Sendable, Equatable, Identifiable {
    public var id: String
    public var icon: String
    public var name: String
    public var timeLabel: String
    public var carbsG: Int
    public var proteinG: Int
    public var fatG: Int
    public var sugarG: Int
    public var saltG: Double

    public var nutrients: NutrientBreakdown {
        NutrientBreakdown(carbsG: carbsG, proteinG: proteinG, fatG: fatG, sugarG: sugarG, saltG: saltG)
    }

    public init(
        id: String = UUID().uuidString,
        icon: String,
        name: String,
        timeLabel: String,
        carbsG: Int,
        proteinG: Int,
        fatG: Int,
        sugarG: Int,
        saltG: Double
    ) {
        self.id = id
        self.icon = icon
        self.name = name
        self.timeLabel = timeLabel
        self.carbsG = carbsG
        self.proteinG = proteinG
        self.fatG = fatG
        self.sugarG = sugarG
        self.saltG = (saltG * 10).rounded() / 10
    }
}

/// Canonical per-day record keyed by ISO-8601 `dateKey` ("YYYY-MM-DD").
/// Stores the day's recorded Current Weight directly alongside the food log entries,
/// plus heavy-exercise and "I ate too much today" flags for O(1) historical retrieval.
public struct DailyRecord: Codable, Sendable, Equatable, Identifiable {
    /// Canonical ISO-8601 date string ("YYYY-MM-DD"), e.g. "2026-10-19".
    public var dateKey: String
    public var id: String { dateKey }
    public var displayLabel: String
    public var shortDate: String
    /// Current weight recorded alongside this day's food log.
    public var weightKg: Double
    public var heavyExercise: Bool
    public var ateTooMuch: Bool
    public var entries: [FoodLogEntry]

    public init(
        dateKey: String,
        displayLabel: String,
        shortDate: String,
        weightKg: Double,
        heavyExercise: Bool = false,
        ateTooMuch: Bool = false,
        entries: [FoodLogEntry] = []
    ) {
        self.dateKey = dateKey
        self.displayLabel = displayLabel
        self.shortDate = shortDate
        self.weightKg = (weightKg * 10).rounded() / 10
        self.heavyExercise = heavyExercise
        self.ateTooMuch = ateTooMuch
        self.entries = entries
    }

    /// Total intake across all logged entries for this day.
    public var totalIntake: NutrientBreakdown {
        entries.reduce(NutrientBreakdown()) { $0 + $1.nutrients }
    }
}

/// A 1-tap meal routine (either suggested from Week 1 eating or user-created).
public struct MealRoutine: Codable, Sendable, Equatable, Identifiable {
    public var id: String
    public var icon: String
    public var shortLabel: String
    public var name: String
    public var frequency: String
    public var defaultTime: String
    public var reason: String
    public var active: Bool
    public var carbsG: Int
    public var proteinG: Int
    public var fatG: Int
    public var sugarG: Int
    public var saltG: Double

    public init(
        id: String,
        icon: String,
        shortLabel: String,
        name: String,
        frequency: String,
        defaultTime: String,
        reason: String,
        active: Bool,
        carbsG: Int,
        proteinG: Int,
        fatG: Int,
        sugarG: Int,
        saltG: Double
    ) {
        self.id = id
        self.icon = icon
        self.shortLabel = shortLabel
        self.name = name
        self.frequency = frequency
        self.defaultTime = defaultTime
        self.reason = reason
        self.active = active
        self.carbsG = carbsG
        self.proteinG = proteinG
        self.fatG = fatG
        self.sugarG = sugarG
        self.saltG = saltG
    }
}

/// Daily-average rollup for a Week or a Year in the Review screen.
/// Explicitly represents daily averages (Avg weight + Daily Average Intake).
public struct PeriodAverageRollup: Codable, Sendable, Equatable, Identifiable {
    public var id: String
    public var label: String
    public var averageWeightKg: Double
    public var deltaLabel: String
    public var dailyAverageIntake: NutrientBreakdown
    public var note: String
    public var dayCount: Int

    public init(
        id: String,
        label: String,
        averageWeightKg: Double,
        deltaLabel: String,
        dailyAverageIntake: NutrientBreakdown,
        note: String,
        dayCount: Int
    ) {
        self.id = id
        self.label = label
        self.averageWeightKg = (averageWeightKg * 10).rounded() / 10
        self.deltaLabel = deltaLabel
        self.dailyAverageIntake = dailyAverageIntake
        self.note = note
        self.dayCount = dayCount
    }
}

/// User profile & onboarding state.
public struct UserProfileV1: Codable, Sendable, Equatable {
    public var onboardingStep: Int // 1: Week 1 Baseline, 2: Habits, 3: Goal Weight, 4: Suggested Routines
    public var baselineCompleted: Bool
    public var goalWeightKg: Double

    public init(onboardingStep: Int = 1, baselineCompleted: Bool = true, goalWeightKg: Double = 78.0) {
        self.onboardingStep = onboardingStep
        self.baselineCompleted = baselineCompleted
        self.goalWeightKg = (goalWeightKg * 10).rounded() / 10
    }
}

/// Top-level Version 1 database envelope stored on disk / iCloud container.
/// Keyed by `daysByDate` ("YYYY-MM-DD" -> DailyRecord) with a pre-sorted `dateIndexDesc`
/// so retrieving any past day, week, or year is instantaneous.
public struct WeightingForLifeDatabaseV1: Codable, Sendable, Equatable {
    public var schemaVersion: Int
    public var updatedAtISO: String
    public var profile: UserProfileV1
    /// O(1) dictionary lookup by canonical ISO date ("YYYY-MM-DD").
    public var daysByDate: [String: DailyRecord]
    /// Descending chronological index of all recorded dateKeys ("YYYY-MM-DD").
    public var dateIndexDesc: [String]
    public var routines: [MealRoutine]

    public init(
        schemaVersion: Int = 1,
        updatedAtISO: String = ISO8601DateFormatter().string(from: Date()),
        profile: UserProfileV1 = UserProfileV1(),
        daysByDate: [String: DailyRecord] = [:],
        dateIndexDesc: [String] = [],
        routines: [MealRoutine] = []
    ) {
        self.schemaVersion = schemaVersion
        self.updatedAtISO = updatedAtISO
        self.profile = profile
        self.daysByDate = daysByDate
        self.dateIndexDesc = dateIndexDesc.isEmpty
            ? Array(daysByDate.keys).sorted(by: >)
            : dateIndexDesc
        self.routines = routines
    }
}
