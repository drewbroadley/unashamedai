import SwiftUI

/// Dribbble 19193291 Inspired Pastel Light Palette
public enum WFLTheme {
    public static let canvasBg = Color(red: 0.969, green: 0.973, blue: 0.984)          // #f7f8fb
    public static let cardBg = Color.white                                             // #ffffff
    public static let subtleBg = Color(red: 0.976, green: 0.980, blue: 0.988)          // #f9fafc
    public static let segTrackBg = Color(red: 0.925, green: 0.937, blue: 0.965)        // #eceff6
    public static let chipBg = Color(red: 0.953, green: 0.957, blue: 0.973)            // #f3f4f8
    public static let border = Color(red: 0.925, green: 0.933, blue: 0.961)            // #eceef5
    public static let textPrimary = Color(red: 0.098, green: 0.110, blue: 0.149)       // #191c26
    public static let textSecondary = Color(red: 0.290, green: 0.310, blue: 0.384)     // #4a4f62
    public static let textMuted = Color(red: 0.494, green: 0.518, blue: 0.592)         // #7e8497
    public static let placeholder = Color(red: 0.612, green: 0.635, blue: 0.706)       // #9ca2b4

    // Pastel Surface Tints & Borders
    public static let tintPeach = Color(red: 0.992, green: 0.925, blue: 0.902)         // #fdece6
    public static let tintPeachBorder = Color(red: 0.976, green: 0.835, blue: 0.784)   // #f9d5c8
    public static let peachInputBorder = Color(red: 0.961, green: 0.812, blue: 0.753)  // #f5cfc0
    public static let peachText = Color(red: 0.373, green: 0.275, blue: 0.239)         // #5f463d

    public static let tintCream = Color(red: 0.996, green: 0.969, blue: 0.902)         // #fef7e6
    public static let tintCreamBorder = Color(red: 0.976, green: 0.902, blue: 0.722)   // #f9e6b8
    public static let creamText = Color(red: 0.561, green: 0.420, blue: 0.196)         // #8f6b32
    public static let amberText = Color(red: 0.706, green: 0.412, blue: 0.055)         // #b4690e
    public static let gaugeTrack = Color(red: 0.961, green: 0.875, blue: 0.671)        // #f5dfab

    public static let tintMint = Color(red: 0.918, green: 0.973, blue: 0.902)          // #eaf8e6
    public static let tintMintBorder = Color(red: 0.804, green: 0.922, blue: 0.769)    // #cdebc4
    public static let mintText = Color(red: 0.302, green: 0.541, blue: 0.043)          // #4d8a0b
    public static let mintDarkText = Color(red: 0.212, green: 0.388, blue: 0.024)      // #366306

    public static let tintBlush = Color(red: 0.988, green: 0.918, blue: 0.949)         // #fceaf2
    public static let tintBlushBorder = Color(red: 0.969, green: 0.804, blue: 0.878)   // #f7cde0
    public static let blushText = Color(red: 0.620, green: 0.208, blue: 0.416)         // #9e356a

    // Dedicated Nutrient Colors (Vibrant Fill + Pastel Track — Never turns red at 100%)
    public static let carbs = Color(red: 0.882, green: 0.188, blue: 0.549)             // #e1308c
    public static let carbsTrack = Color(red: 0.980, green: 0.839, blue: 0.910)        // #fad6e8

    public static let protein = Color(red: 0.478, green: 0.780, blue: 0.122)           // #7ac71f
    public static let proteinTrack = Color(red: 0.886, green: 0.961, blue: 0.784)      // #e2f5c8

    public static let fat = Color(red: 0.439, green: 0.000, blue: 0.875)               // #7000df
    public static let fatTrack = Color(red: 0.898, green: 0.820, blue: 0.980)          // #e5d1fa

    public static let sugar = Color(red: 0.957, green: 0.510, blue: 0.396)             // #f48265
    public static let sugarTrack = Color(red: 0.992, green: 0.886, blue: 0.855)        // #fde2da

    public static let salt = Color(red: 0.169, green: 0.604, blue: 0.953)              // #2b9af3
    public static let saltTrack = Color(red: 0.839, green: 0.925, blue: 0.992)         // #d6ecfd

    // Brand Accents
    public static let accentCoral = Color(red: 0.957, green: 0.510, blue: 0.396)       // #f48265
    public static let accentDark = Color(red: 0.875, green: 0.392, blue: 0.275)        // #df6446
    public static let accentPink = Color(red: 0.882, green: 0.188, blue: 0.549)        // #e1308c
}

public enum WFLTab: String, CaseIterable, Sendable {
    case onboarding = "Setup"
    case log = "Today"
    case routines = "Routines"
    case review = "Review"

    public var dockLabel: String {
        switch self {
        case .onboarding: return "✨ Setup"
        case .log: return "🍽️ Today"
        case .routines: return "🔁 Routines"
        case .review: return "📊 Review"
        }
    }
}

public enum WFLReviewPeriod: String, CaseIterable, Sendable {
    case days = "Days"
    case weeks = "Weeks"
    case years = "Years"
}

public struct WeightingForLifeRootView: View {
    @State private var store: FoodAndWeightStore
    @State private var activeTab: WFLTab = .log
    @State private var selectedDateIndex: Int = 0
    @State private var weightDrawerOpen: Bool = false
    @State private var intakeExpanded: Bool = false
    @State private var expandedEntryID: String? = nil
    @State private var searchQuery: String = ""
    @State private var matchLimit: Int = 10
    @State private var timeIndex: Int = 0
    @State private var reviewPeriod: WFLReviewPeriod = .days
    @State private var newRoutineFoodIndex: Int = 9
    @State private var newRoutineFreqIndex: Int = 0
    @FocusState private var isSearchFocused: Bool

    private let timeOptions = ["Now", "8:00 am", "12:30 pm"]
    private let freqOptions = ["Every day", "Weekdays", "Weekends", "🔥 Exercise days", "Tue / Thu / Sun", "2× / week"]
    private let searchEngine = NZFCDSearchEngine()

    public init(store: FoodAndWeightStore = FoodAndWeightStore()) {
        _store = State(initialValue: store)
    }

    private var isSearching: Bool {
        isSearchFocused || !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func logFoodItem(_ item: NZFCDFoodItem) {
        let chosenTime = timeOptions[timeIndex] == "Now" ? "2:24 pm" : timeOptions[timeIndex]
        store.addFoodEntry(
            FoodLogEntry(
                icon: item.icon,
                name: item.name,
                timeLabel: chosenTime,
                carbsG: item.carbsG,
                proteinG: item.proteinG,
                fatG: item.fatG,
                sugarG: item.sugarG,
                saltG: item.saltG
            ),
            to: currentDateKey
        )
        searchQuery = ""
        isSearchFocused = false
    }

    private var currentDateKey: String {
        let keys = store.database.dateIndexDesc
        guard !keys.isEmpty else { return "2026-10-19" }
        let safeIdx = max(0, min(selectedDateIndex, keys.count - 1))
        return keys[safeIdx]
    }

    private var currentDay: DailyRecord {
        store.day(for: currentDateKey) ?? DailyRecord(
            dateKey: "2026-10-19",
            displayLabel: "Today",
            shortDate: "Mon 19 Oct",
            weightKg: 85.4
        )
    }

    private var isBaselineWeek1: Bool {
        activeTab == .onboarding && store.database.profile.onboardingStep < 3
    }

    public var body: some View {
        VStack(spacing: 11) {
            headerBar

            if weightDrawerOpen {
                weightDrawer
            }

            Group {
                switch activeTab {
                case .onboarding:
                    onboardingStepView
                case .log:
                    dailyLogView
                case .routines:
                    routinesView
                case .review:
                    reviewView
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

            if !(activeTab == .log && isSearching) {
                bottomCapsuleDock
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 10)
        .background(WFLTheme.canvasBg.ignoresSafeArea())
        .foregroundStyle(WFLTheme.textPrimary)
        .environment(\.colorScheme, .light)
        .preferredColorScheme(.light)
    }

    // MARK: - Single-Line Height-Locked Header Bar (30pt)

    private var headerBar: some View {
        HStack(spacing: 6) {
            HStack(spacing: 3) {
                Button {
                    let maxIdx = max(0, store.database.dateIndexDesc.count - 1)
                    if selectedDateIndex < maxIdx {
                        selectedDateIndex += 1
                        activeTab = .log
                    }
                } label: {
                    Text("‹")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(WFLTheme.textPrimary)
                        .frame(width: 24, height: 24)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(WFLTheme.border, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)

                Text(currentDay.displayLabel)
                    .font(.system(size: 13, weight: .heavy))
                    .foregroundStyle(WFLTheme.textPrimary)
                    .lineLimit(1)
                    .frame(width: 72)

                Button {
                    if selectedDateIndex > 0 {
                        selectedDateIndex -= 1
                        activeTab = .log
                    }
                } label: {
                    Text("›")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(WFLTheme.textPrimary)
                        .frame(width: 24, height: 24)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(WFLTheme.border, lineWidth: 1)
                        )
                        .opacity(selectedDateIndex == 0 ? 0.35 : 1.0)
                }
                .buttonStyle(.plain)
            }

            Spacer(minLength: 4)

            HStack(spacing: 4) {
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        weightDrawerOpen.toggle()
                    }
                } label: {
                    Text(String(format: "⚖️ %.1fkg", currentDay.weightKg))
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(WFLTheme.amberText)
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                        .padding(.horizontal, 9)
                        .frame(height: 28)
                        .background(WFLTheme.tintCream)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule().stroke(WFLTheme.tintCreamBorder, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)

                Button {
                    store.toggleHeavyExercise(for: currentDateKey)
                } label: {
                    Text(currentDay.heavyExercise ? "🔥 Exercise" : "Normal")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(currentDay.heavyExercise ? WFLTheme.mintText : WFLTheme.textMuted)
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                        .padding(.horizontal, 9)
                        .frame(height: 28)
                        .background(currentDay.heavyExercise ? WFLTheme.tintMint : Color.white)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule().stroke(currentDay.heavyExercise ? WFLTheme.tintMintBorder : WFLTheme.border, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)

                Button {
                    activeTab = (activeTab == .log) ? .review : .log
                } label: {
                    Text(activeTab == .log ? "Review" : "← Log")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(activeTab == .log ? WFLTheme.textMuted : Color.white)
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                        .padding(.horizontal, 9)
                        .frame(height: 28)
                        .background(activeTab == .log ? Color.white : WFLTheme.accentCoral)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule().stroke(activeTab == .log ? WFLTheme.border : WFLTheme.accentCoral, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .frame(height: 30)
    }

    // MARK: - Butter-Cream Weight Drawer (Arc Gauge + Current & Goal Sliders)

    private var weightDrawer: some View {
        let ratio = max(0.1, min(1.0, (currentDay.weightKg - 50.0) / 80.0))
        return VStack(alignment: .leading, spacing: 9) {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("MY WEIGHT (\(currentDay.displayLabel.uppercased()))")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(WFLTheme.creamText)
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text(String(format: "%.1f kg", currentDay.weightKg))
                            .font(.system(size: 20, weight: .heavy))
                            .foregroundStyle(WFLTheme.textPrimary)
                        Text(isBaselineWeek1 ? "Wk 1 Baseline" : String(format: "Goal %.1f kg", store.database.profile.goalWeightKg))
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(WFLTheme.creamText)
                    }
                }

                Spacer(minLength: 4)

                WeightArcGauge(progress: ratio)
                    .frame(width: 68, height: 38)

                HStack(spacing: 4) {
                    Button {
                        store.setWeight(currentDay.weightKg - 0.1, for: currentDateKey)
                    } label: {
                        Text("-0.1")
                            .font(.system(size: 12, weight: .heavy))
                            .foregroundStyle(WFLTheme.textPrimary)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 6)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(WFLTheme.tintCreamBorder, lineWidth: 1))
                    }
                    .buttonStyle(.plain)

                    Button {
                        store.setWeight(currentDay.weightKg + 0.1, for: currentDateKey)
                    } label: {
                        Text("+0.1")
                            .font(.system(size: 12, weight: .heavy))
                            .foregroundStyle(WFLTheme.textPrimary)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 6)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(WFLTheme.tintCreamBorder, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }

            HStack(spacing: 10) {
                Text("Current")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(WFLTheme.creamText)
                    .frame(width: 54, alignment: .leading)
                Slider(
                    value: Binding(
                        get: { currentDay.weightKg },
                        set: { store.setWeight($0, for: currentDateKey) }
                    ),
                    in: 50...130,
                    step: 0.1
                )
                .tint(WFLTheme.accentCoral)
            }

            Divider().overlay(WFLTheme.tintCreamBorder)

            if !isBaselineWeek1 {
                HStack(spacing: 10) {
                    Text("Goal")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(WFLTheme.creamText)
                        .frame(width: 54, alignment: .leading)
                    Slider(
                        value: Binding(
                            get: { store.database.profile.goalWeightKg },
                            set: { store.setGoalWeight($0) }
                        ),
                        in: 50...130,
                        step: 0.5
                    )
                    .tint(WFLTheme.accentCoral)
                    Text(String(format: "%.1f kg", store.database.profile.goalWeightKg))
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(WFLTheme.creamText)
                        .frame(width: 52, alignment: .trailing)
                }
            } else {
                HStack {
                    Text("🔒 Goal weight unlocks after Week 1 baseline")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(WFLTheme.creamText)
                    Spacer()
                    Button("View Setup →") {
                        activeTab = .onboarding
                    }
                    .font(.system(size: 11, weight: .heavy))
                    .foregroundStyle(WFLTheme.accentDark)
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(13)
        .background(WFLTheme.tintCream)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(WFLTheme.tintCreamBorder, lineWidth: 1)
        )
    }

    // MARK: - Daily Log View

    private var dailyLogView: some View {
        let totals = currentDay.totalIntake
        let limits = store.limits(for: currentDateKey)
        let trimmedQuery = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        let matches: [RankedNZFCDMatch] = {
            if !trimmedQuery.isEmpty {
                return searchEngine.search(searchQuery, limit: matchLimit)
            } else if isSearchFocused {
                return searchEngine.defaultSuggestions(limit: matchLimit)
            } else {
                return []
            }
        }()

        return VStack(spacing: 10) {
            // 1. Dribbble-Style 5-Nutrient Strip (Vibrant fills on pastel tracks, never turns red)
            Button {
                withAnimation(.easeInOut(duration: 0.18)) {
                    intakeExpanded.toggle()
                }
            } label: {
                VStack(spacing: 10) {
                    HStack(spacing: 8) {
                        nutrientMiniBar("Carbs", val: Double(totals.carbsG), max: Double(limits.carbsG), color: WFLTheme.carbs, track: WFLTheme.carbsTrack)
                        nutrientMiniBar("Protein", val: Double(totals.proteinG), max: Double(limits.proteinG), color: WFLTheme.protein, track: WFLTheme.proteinTrack)
                        nutrientMiniBar("Fat", val: Double(totals.fatG), max: Double(limits.fatG), color: WFLTheme.fat, track: WFLTheme.fatTrack)
                        nutrientMiniBar("Sugar", val: Double(totals.sugarG), max: Double(limits.sugarG), color: WFLTheme.sugar, track: WFLTheme.sugarTrack)
                        nutrientMiniBar("Salt", val: totals.saltG, max: limits.saltG, color: WFLTheme.salt, track: WFLTheme.saltTrack)

                        Text(intakeExpanded ? "▲" : "▼")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(WFLTheme.textMuted)
                            .frame(width: 22, height: 22)
                            .background(WFLTheme.chipBg)
                            .clipShape(Circle())
                    }

                    if intakeExpanded {
                        Divider().overlay(WFLTheme.border)
                        VStack(spacing: 6) {
                            nutrientDetailRow(name: "Carbs", value: "\(totals.carbsG)g", limit: "\(limits.carbsG)g", color: WFLTheme.carbs)
                            nutrientDetailRow(name: "Protein", value: "\(totals.proteinG)g", limit: "\(limits.proteinG)g", color: WFLTheme.protein)
                            nutrientDetailRow(name: "Fat", value: "\(totals.fatG)g", limit: "\(limits.fatG)g", color: WFLTheme.fat)
                            nutrientDetailRow(name: "Sugar", value: "\(totals.sugarG)g", limit: "\(limits.sugarG)g", color: WFLTheme.sugar)
                            nutrientDetailRow(name: "Salt", value: String(format: "%.1fg", totals.saltG), limit: String(format: "%.1fg", limits.saltG), color: WFLTheme.salt)
                        }
                    }
                }
                .padding(13)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 22))
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(WFLTheme.border, lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(.plain)

            // 2. Soft Peach Meal Search Card + Live Keystroke Autocomplete + 1-Tap Routines
            VStack(alignment: .leading, spacing: 9) {
                HStack(spacing: 6) {
                    HStack(spacing: 6) {
                        Text("🔍")
                            .font(.system(size: 12))

                        TextField(
                            "",
                            text: $searchQuery,
                            prompt: Text("Type food to autocomplete (e.g. egg, vogels, pie)...")
                                .foregroundStyle(WFLTheme.placeholder)
                        )
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(WFLTheme.textPrimary)
                        .tint(WFLTheme.accentCoral)
                        .focused($isSearchFocused)
                        .autocorrectionDisabled(true)
                        .textInputAutocapitalization(.never)
                        .submitLabel(.done)
                        .onSubmit {
                            if !trimmedQuery.isEmpty, let top = matches.first {
                                logFoodItem(top.item)
                            } else {
                                isSearchFocused = false
                            }
                        }

                        if !searchQuery.isEmpty {
                            Button {
                                searchQuery = ""
                            } label: {
                                Text("×")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(WFLTheme.textMuted)
                                    .frame(width: 20, height: 20)
                                    .background(WFLTheme.chipBg)
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 11)
                    .padding(.vertical, 9)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(isSearchFocused ? WFLTheme.accentCoral : WFLTheme.peachInputBorder, lineWidth: isSearchFocused ? 1.5 : 1)
                    )

                    Button {
                        timeIndex = (timeIndex + 1) % timeOptions.count
                    } label: {
                        Text(timeOptions[timeIndex])
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Color.white)
                            .padding(.horizontal, 11)
                            .frame(height: 34)
                            .background(WFLTheme.accentCoral)
                            .clipShape(Capsule())
                            .shadow(color: WFLTheme.accentCoral.opacity(0.3), radius: 5, x: 0, y: 2)
                    }
                    .buttonStyle(.plain)

                    if isSearching {
                        Button {
                            searchQuery = ""
                            isSearchFocused = false
                        } label: {
                            Text("Done")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(WFLTheme.accentDark)
                                .padding(.horizontal, 10)
                                .frame(height: 34)
                                .background(Color.white)
                                .clipShape(Capsule())
                                .overlay(Capsule().stroke(WFLTheme.peachInputBorder, lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                }

                // Instant Top-1 Autocomplete Pill (1-tap or Return key to add)
                if !trimmedQuery.isEmpty, let top = matches.first {
                    Button {
                        logFoodItem(top.item)
                    } label: {
                        HStack(spacing: 6) {
                            Text("⏎")
                                .font(.system(size: 11, weight: .heavy))
                                .foregroundStyle(Color.white)
                                .frame(width: 20, height: 20)
                                .background(WFLTheme.accentCoral)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                            Text("\(top.item.icon) \(top.item.name)")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(WFLTheme.textPrimary)
                                .lineLimit(1)
                            Spacer()
                            Text("Tap to add")
                                .font(.system(size: 11, weight: .heavy))
                                .foregroundStyle(WFLTheme.accentDark)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(WFLTheme.accentCoral, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }

                // Live Autocomplete Results Dropdown (expands to fill space above keyboard when typing)
                if isSearching {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(trimmedQuery.isEmpty ? "Popular NZ foods (type to autocomplete)" : "Autocomplete matches (\(matches.count) shown)")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(WFLTheme.textMuted)
                            Spacer()
                            Button {
                                matchLimit = (matchLimit == 10) ? 25 : 10
                            } label: {
                                Text(matchLimit == 10 ? "Showing 10 · Show 25" : "Showing 25 · Show 10")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(WFLTheme.accentDark)
                                    .padding(.horizontal, 9)
                                    .padding(.vertical, 3)
                                    .background(WFLTheme.tintPeach)
                                    .clipShape(Capsule())
                                    .overlay(Capsule().stroke(WFLTheme.tintPeachBorder, lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                        }

                        if matches.isEmpty {
                            Text("No NZFCD food matches \"\(trimmedQuery)\"")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(WFLTheme.textMuted)
                                .padding(.vertical, 12)
                                .frame(maxWidth: .infinity)
                        } else {
                            ScrollView {
                                VStack(spacing: 4) {
                                    ForEach(matches) { m in
                                        Button {
                                            logFoodItem(m.item)
                                        } label: {
                                            HStack(spacing: 8) {
                                                Text("\(m.rank).")
                                                    .font(.system(size: 11, weight: .bold))
                                                    .foregroundStyle(WFLTheme.textMuted)
                                                    .frame(width: 18, alignment: .trailing)
                                                Text(m.item.icon)
                                                    .font(.system(size: 15))
                                                VStack(alignment: .leading, spacing: 1) {
                                                    Text(m.item.name)
                                                        .font(.system(size: 12, weight: .semibold))
                                                        .foregroundStyle(WFLTheme.textPrimary)
                                                        .lineLimit(1)
                                                    Text("\(m.item.carbsG)C · \(m.item.proteinG)P · \(m.item.fatG)F · \(m.item.sugarG)Su · \(String(format: "%.1f", m.item.saltG))Sa")
                                                        .font(.system(size: 11))
                                                        .foregroundStyle(WFLTheme.textMuted)
                                                }
                                                Spacer()
                                                Circle()
                                                    .fill(m.score >= 120 ? WFLTheme.protein : (m.score >= 50 ? WFLTheme.sugar : WFLTheme.placeholder))
                                                    .frame(width: 6, height: 6)
                                                Text("+")
                                                    .font(.system(size: 13, weight: .heavy))
                                                    .foregroundStyle(Color.white)
                                                    .frame(width: 22, height: 22)
                                                    .background(WFLTheme.accentCoral)
                                                    .clipShape(Circle())
                                            }
                                            .padding(.horizontal, 9)
                                            .padding(.vertical, 7)
                                            .background(WFLTheme.subtleBg)
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                            .frame(minHeight: 165, maxHeight: .infinity)
                        }
                    }
                    .padding(9)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(WFLTheme.peachInputBorder, lineWidth: 1)
                    )
                    .layoutPriority(1)
                }

                // 1-Tap Active Routine Chips + Link to Routines Page
                if !isSearching {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(store.database.routines.filter(\.active)) { r in
                                Button {
                                    let chosenTime = timeOptions[timeIndex] == "Now" ? r.defaultTime : timeOptions[timeIndex]
                                    store.addFoodEntry(
                                        FoodLogEntry(
                                            icon: r.icon,
                                            name: r.name,
                                            timeLabel: chosenTime,
                                            carbsG: r.carbsG,
                                            proteinG: r.proteinG,
                                            fatG: r.fatG,
                                            sugarG: r.sugarG,
                                            saltG: r.saltG
                                        ),
                                        to: currentDateKey
                                    )
                                } label: {
                                    Text("\(r.icon) \(r.shortLabel)")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(WFLTheme.textSecondary)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(Color.white)
                                        .clipShape(Capsule())
                                        .overlay(
                                            Capsule().stroke(WFLTheme.peachInputBorder, lineWidth: 1)
                                        )
                                }
                                .buttonStyle(.plain)
                            }

                            Button {
                                activeTab = .routines
                            } label: {
                                Text("🔁 Routines")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(WFLTheme.mintText)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(WFLTheme.tintMint)
                                    .clipShape(Capsule())
                                    .overlay(
                                        Capsule().stroke(WFLTheme.tintMintBorder, lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(13)
            .background(WFLTheme.tintPeach)
            .clipShape(RoundedRectangle(cornerRadius: 22))
            .overlay(
                RoundedRectangle(cornerRadius: 22)
                    .stroke(WFLTheme.tintPeachBorder, lineWidth: 1)
            )
            .layoutPriority(isSearching ? 1 : 0)

            if !isSearching {
                // 3. Recorded Weight Row + Food Entries List
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 7) {
                        Button {
                            withAnimation(.easeInOut(duration: 0.18)) {
                                weightDrawerOpen.toggle()
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Text("⚖️")
                                    .font(.system(size: 15))
                                    .frame(width: 30, height: 30)
                                    .background(Color.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(String(format: "Recorded weight (%@): %.1f kg", currentDay.displayLabel, currentDay.weightKg))
                                        .font(.system(size: 12, weight: .heavy))
                                        .foregroundStyle(WFLTheme.textPrimary)
                                    Text(isBaselineWeek1 ? "Week 1 Baseline · Tap to edit" : String(format: "Goal %.1f kg · Tap to edit", store.database.profile.goalWeightKg))
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundStyle(WFLTheme.creamText)
                                }
                                Spacer()
                                Text("Edit")
                                    .font(.system(size: 11, weight: .heavy))
                                    .foregroundStyle(WFLTheme.amberText)
                                    .padding(.horizontal, 9)
                                    .padding(.vertical, 4)
                                    .background(Color.white)
                                    .clipShape(Capsule())
                                    .overlay(
                                        Capsule().stroke(WFLTheme.tintCreamBorder, lineWidth: 1)
                                    )
                            }
                            .padding(.horizontal, 13)
                            .padding(.vertical, 10)
                            .background(WFLTheme.tintCream)
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                            .overlay(
                                RoundedRectangle(cornerRadius: 18)
                                    .stroke(WFLTheme.tintCreamBorder, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)

                        let iconTints = [WFLTheme.tintPeach, WFLTheme.tintMint, WFLTheme.tintCream, WFLTheme.tintBlush]
                        ForEach(Array(currentDay.entries.enumerated()), id: \.element.id) { idx, entry in
                            let isExpanded = (expandedEntryID == entry.id)
                            VStack(spacing: 8) {
                                HStack(spacing: 10) {
                                    Text(entry.icon)
                                        .font(.system(size: 17))
                                        .frame(width: 34, height: 34)
                                        .background(iconTints[idx % iconTints.count])
                                        .clipShape(RoundedRectangle(cornerRadius: 12))

                                    Text(entry.name)
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(WFLTheme.textPrimary)
                                        .lineLimit(1)

                                    Spacer()

                                    Text(entry.timeLabel)
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(WFLTheme.textMuted)

                                    Button {
                                        store.removeFoodEntry(id: entry.id, from: currentDateKey)
                                    } label: {
                                        Text("×")
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundStyle(WFLTheme.textMuted)
                                            .frame(width: 22, height: 22)
                                            .background(WFLTheme.chipBg)
                                            .clipShape(Circle())
                                    }
                                    .buttonStyle(.plain)
                                }

                                if isExpanded {
                                    Divider().overlay(WFLTheme.border)
                                    HStack {
                                        Text("\(entry.carbsG)g Carbs").foregroundStyle(WFLTheme.carbs)
                                        Spacer()
                                        Text("\(entry.proteinG)g Protein").foregroundStyle(WFLTheme.protein)
                                        Spacer()
                                        Text("\(entry.fatG)g Fat").foregroundStyle(WFLTheme.fat)
                                        Spacer()
                                        Text("\(entry.sugarG)g Sugar").foregroundStyle(WFLTheme.sugar)
                                        Spacer()
                                        Text(String(format: "%.1fg Salt", entry.saltG)).foregroundStyle(WFLTheme.salt)
                                    }
                                    .font(.system(size: 11, weight: .bold))
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 9)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                            .overlay(
                                RoundedRectangle(cornerRadius: 18)
                                    .stroke(WFLTheme.border, lineWidth: 1)
                            )
                            .shadow(color: Color.black.opacity(0.02), radius: 5, x: 0, y: 2)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.15)) {
                                    expandedEntryID = isExpanded ? nil : entry.id
                                }
                            }
                        }
                    }
                }

                // 4. Bottom "I ate too much today" Rebalance Button
                Button {
                    store.toggleAteTooMuch(for: currentDateKey)
                } label: {
                    HStack {
                        Text(currentDay.ateTooMuch ? "✓ Next day’s limits rebalanced (-15%)" : "😮‍💨 I ate too much today")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(currentDay.ateTooMuch ? WFLTheme.accentPink : WFLTheme.textMuted)
                        Spacer()
                        Text(currentDay.ateTooMuch ? "Undo" : "Balance tomorrow")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(currentDay.ateTooMuch ? WFLTheme.accentPink : WFLTheme.accentDark)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 11)
                    .background(currentDay.ateTooMuch ? WFLTheme.tintBlush : Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(currentDay.ateTooMuch ? WFLTheme.tintBlushBorder : WFLTheme.border, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func nutrientMiniBar(_ title: String, val: Double, max: Double, color: Color, track: Color) -> some View {
        let pct = min(100, Int(((val / Swift.max(0.1, max)) * 100.0).rounded()))
        return VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(WFLTheme.textMuted)
                .lineLimit(1)
            Text("\(pct)%")
                .font(.system(size: 13, weight: .heavy))
                .foregroundStyle(WFLTheme.textPrimary)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(track)
                    Capsule().fill(color).frame(width: geo.size.width * CGFloat(pct) / 100.0)
                }
            }
            .frame(height: 7)
        }
    }

    private func nutrientDetailRow(name: String, value: String, limit: String, color: Color) -> some View {
        HStack {
            Text("● \(name)")
                .font(.system(size: 12, weight: .heavy))
                .foregroundStyle(color)
            Spacer()
            HStack(spacing: 2) {
                Text(value)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(WFLTheme.textPrimary)
                Text("/ \(limit)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(WFLTheme.textMuted)
            }
        }
    }

    // MARK: - 4 Clean Step Onboarding Pages

    private var onboardingStepView: some View {
        let step = store.database.profile.onboardingStep
        let chronologicalDays = store.allDaysAscending()
        let descDays = store.allDaysDescending()
        let avg = store.computeDailyAverage(for: descDays)
        let targetLim = store.limits(for: currentDateKey)

        return VStack(spacing: 12) {
            // Custom 4-step segmented bar
            HStack(spacing: 4) {
                ForEach(1...4, id: \.self) { s in
                    let titles = ["1 · Week 1", "2 · Habits", "3 · Goal", "4 · Routines"]
                    Button {
                        store.setOnboardingStep(s)
                    } label: {
                        Text(titles[s - 1])
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(step == s ? WFLTheme.textPrimary : WFLTheme.textMuted)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 7)
                            .background(step == s ? Color.white : Color.clear)
                            .clipShape(RoundedRectangle(cornerRadius: 11))
                            .shadow(color: step == s ? Color.black.opacity(0.06) : .clear, radius: 4, x: 0, y: 2)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(3)
            .background(WFLTheme.segTrackBg)
            .clipShape(RoundedRectangle(cornerRadius: 14))

            if step == 1 {
                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("STEP 1 OF 4 · WEEK 1 BASELINE")
                                .font(.system(size: 11, weight: .heavy))
                                .foregroundStyle(WFLTheme.accentDark)
                            Spacer()
                            Text("7 / 7 Days")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(Color.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(WFLTheme.accentCoral)
                                .clipShape(Capsule())
                        }
                        Text("Record 1 week of normal eating first")
                            .font(.system(size: 20, weight: .heavy))
                            .foregroundStyle(WFLTheme.textPrimary)
                        Text("Log what you normally eat plus your Current Weight each day. We wait until Day 7 before asking for a Goal Weight.")
                            .font(.system(size: 13))
                            .foregroundStyle(WFLTheme.peachText)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 0)

                    HStack(spacing: 5) {
                        ForEach(Array(chronologicalDays.enumerated()), id: \.element.id) { idx, d in
                            let isToday = (idx == chronologicalDays.count - 1)
                            let shortDay = d.shortDate.split(separator: " ").first.map(String.init) ?? d.displayLabel
                            Button {
                                selectedDateIndex = max(0, descDays.count - 1 - idx)
                                activeTab = .log
                            } label: {
                                VStack(spacing: 3) {
                                    Text(shortDay)
                                        .font(.system(size: 10, weight: .bold))
                                        .opacity(0.85)
                                    Text("✓")
                                        .font(.system(size: 13, weight: .heavy))
                                    Text(String(format: "%.1f", d.weightKg))
                                        .font(.system(size: 10, weight: .heavy))
                                }
                                .foregroundStyle(isToday ? Color.white : WFLTheme.textPrimary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(isToday ? WFLTheme.accentPink : WFLTheme.tintMint)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(isToday ? WFLTheme.accentPink : WFLTheme.tintMintBorder, lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Spacer(minLength: 0)

                    HStack(spacing: 8) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("⚖️ Current Weight")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(WFLTheme.textMuted)
                            let firstW = chronologicalDays.first?.weightKg ?? 86.4
                            let lastW = descDays.first?.weightKg ?? 85.4
                            Text(String(format: "%.1f → %.1f kg", firstW, lastW))
                                .font(.system(size: 15, weight: .heavy))
                                .foregroundStyle(WFLTheme.textPrimary)
                            Text("7 days recorded")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(WFLTheme.mintText)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(WFLTheme.tintPeachBorder, lineWidth: 1))

                        VStack(alignment: .leading, spacing: 3) {
                            Text("🥣 Normal Eating")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(WFLTheme.textMuted)
                            let totalMeals = descDays.reduce(0) { $0 + $1.entries.count }
                            Text("\(totalMeals) Meals")
                                .font(.system(size: 15, weight: .heavy))
                                .foregroundStyle(WFLTheme.textPrimary)
                            Text("🔒 Goal unlocks next")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(WFLTheme.accentDark)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(WFLTheme.tintPeachBorder, lineWidth: 1))
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .background(WFLTheme.tintPeach)
                .clipShape(RoundedRectangle(cornerRadius: 22))
                .overlay(RoundedRectangle(cornerRadius: 22).stroke(WFLTheme.tintPeachBorder, lineWidth: 1))

                onboardingCTAButton(title: "Next: Your Eating Behaviours", trailing: "Step 2 →") {
                    store.setOnboardingStep(2)
                }
            } else if step == 2 {
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("STEP 2 OF 4 · BEHAVIOURS LEARNED")
                                .font(.system(size: 11, weight: .heavy))
                                .foregroundStyle(WFLTheme.accentDark)
                            Spacer()
                            Text(String(format: "Avg %.1f kg", avg.averageWeightKg))
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(Color.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(WFLTheme.accentCoral)
                                .clipShape(Capsule())
                        }
                        Text("What we noticed in Week 1")
                            .font(.system(size: 20, weight: .heavy))
                            .foregroundStyle(WFLTheme.textPrimary)
                        HStack(spacing: 4) {
                            Text("Daily avg:")
                                .foregroundStyle(WFLTheme.textMuted)
                            Text("\(avg.dailyAverageIntake.carbsG)g C").foregroundStyle(WFLTheme.carbs).bold()
                            Text("·").foregroundStyle(WFLTheme.textMuted)
                            Text("\(avg.dailyAverageIntake.proteinG)g P").foregroundStyle(WFLTheme.protein).bold()
                            Text("·").foregroundStyle(WFLTheme.textMuted)
                            Text("\(avg.dailyAverageIntake.fatG)g F").foregroundStyle(WFLTheme.fat).bold()
                            Text("·").foregroundStyle(WFLTheme.textMuted)
                            Text("\(avg.dailyAverageIntake.sugarG)g Su").foregroundStyle(WFLTheme.sugar).bold()
                            Text("·").foregroundStyle(WFLTheme.textMuted)
                            Text(String(format: "%.1fg Sa", avg.dailyAverageIntake.saltG)).foregroundStyle(WFLTheme.salt).bold()
                        }
                        .font(.system(size: 12))
                    }

                    Spacer(minLength: 0)

                    VStack(spacing: 9) {
                        behaviourCard(
                            title: "☕ Morning Flat White Habit",
                            subtitle: "Logged 6 of 7 mornings around 7:45 am",
                            badge: "Routine",
                            bg: WFLTheme.tintPeach,
                            border: WFLTheme.tintPeachBorder,
                            subColor: WFLTheme.peachText,
                            badgeBg: WFLTheme.accentCoral,
                            badgeFg: .white
                        )
                        behaviourCard(
                            title: "🥚 High-Protein Breakfasts",
                            subtitle: "Oats or Poached Eggs on Vogels 5/7 days",
                            badge: "Keep",
                            bg: WFLTheme.tintMint,
                            border: WFLTheme.tintMintBorder,
                            subColor: WFLTheme.mintText,
                            badgeBg: WFLTheme.tintMint,
                            badgeFg: WFLTheme.mintText
                        )
                        behaviourCard(
                            title: "🍟 Saturday Takeaway Spike",
                            subtitle: "Pie + fish & chips pushed Salt & Fat high",
                            badge: "Balance",
                            bg: WFLTheme.tintBlush,
                            border: WFLTheme.tintBlushBorder,
                            subColor: WFLTheme.blushText,
                            badgeBg: Color.white,
                            badgeFg: WFLTheme.accentPink
                        )
                    }

                    Spacer(minLength: 0)
                }
                .padding(16)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 22))
                .overlay(RoundedRectangle(cornerRadius: 22).stroke(WFLTheme.border, lineWidth: 1))

                HStack(spacing: 8) {
                    onboardingBackButton { store.setOnboardingStep(1) }
                    onboardingCTAButton(title: "Next: Set Goal Weight", trailing: "Step 3 →") {
                        store.setOnboardingStep(3)
                    }
                }
            } else if step == 3 {
                let goalKg = store.database.profile.goalWeightKg
                let goalRatio = max(0.1, min(1.0, (goalKg - 55.0) / 60.0))

                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("STEP 3 OF 4 · GOAL UNLOCKED")
                                .font(.system(size: 11, weight: .heavy))
                                .foregroundStyle(WFLTheme.amberText)
                            Spacer()
                            Text(String(format: "Current: %.1f kg", currentDay.weightKg))
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(WFLTheme.creamText)
                        }
                        Text("Set your Goal Weight")
                            .font(.system(size: 20, weight: .heavy))
                            .foregroundStyle(WFLTheme.textPrimary)
                        Text("Now that your Week 1 baseline is recorded, choose your target weight.")
                            .font(.system(size: 13))
                            .foregroundStyle(WFLTheme.creamText)
                    }

                    Spacer(minLength: 0)

                    VStack(spacing: 10) {
                        WeightArcGauge(progress: goalRatio)
                            .frame(width: 120, height: 64)

                        HStack(spacing: 14) {
                            Button {
                                store.setGoalWeight(goalKg - 0.5)
                            } label: {
                                Text("-0.5")
                                    .font(.system(size: 13, weight: .heavy))
                                    .foregroundStyle(WFLTheme.textPrimary)
                                    .padding(.horizontal, 13)
                                    .padding(.vertical, 7)
                                    .background(Color.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(WFLTheme.tintCreamBorder, lineWidth: 1))
                            }
                            .buttonStyle(.plain)

                            VStack(spacing: 2) {
                                Text(String(format: "%.1f kg", goalKg))
                                    .font(.system(size: 26, weight: .heavy))
                                    .foregroundStyle(WFLTheme.textPrimary)
                                Text(String(format: "%+.1f kg from current", goalKg - currentDay.weightKg))
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(WFLTheme.textMuted)
                            }

                            Button {
                                store.setGoalWeight(goalKg + 0.5)
                            } label: {
                                Text("+0.5")
                                    .font(.system(size: 13, weight: .heavy))
                                    .foregroundStyle(WFLTheme.textPrimary)
                                    .padding(.horizontal, 13)
                                    .padding(.vertical, 7)
                                    .background(Color.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(WFLTheme.tintCreamBorder, lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                        }

                        Slider(
                            value: Binding(
                                get: { store.database.profile.goalWeightKg },
                                set: { store.setGoalWeight($0) }
                            ),
                            in: 55...115,
                            step: 0.5
                        )
                        .tint(WFLTheme.accentCoral)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(WFLTheme.tintCreamBorder, lineWidth: 1))

                    Spacer(minLength: 0)

                    HStack {
                        Text("Daily Targets")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(WFLTheme.creamText)
                        Spacer()
                        HStack(spacing: 4) {
                            Text("\(targetLim.carbsG)C").foregroundStyle(WFLTheme.carbs)
                            Text("·").foregroundStyle(WFLTheme.textMuted)
                            Text("\(targetLim.proteinG)P").foregroundStyle(WFLTheme.protein)
                            Text("·").foregroundStyle(WFLTheme.textMuted)
                            Text("\(targetLim.fatG)F").foregroundStyle(WFLTheme.fat)
                            Text("·").foregroundStyle(WFLTheme.textMuted)
                            Text("\(targetLim.sugarG)Su").foregroundStyle(WFLTheme.sugar)
                            Text("·").foregroundStyle(WFLTheme.textMuted)
                            Text(String(format: "%.1fSa", targetLim.saltG)).foregroundStyle(WFLTheme.salt)
                        }
                        .font(.system(size: 12, weight: .heavy))
                    }
                    .padding(.horizontal, 13)
                    .padding(.vertical, 11)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(WFLTheme.tintCreamBorder, lineWidth: 1))
                }
                .padding(16)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .background(WFLTheme.tintCream)
                .clipShape(RoundedRectangle(cornerRadius: 22))
                .overlay(RoundedRectangle(cornerRadius: 22).stroke(WFLTheme.tintCreamBorder, lineWidth: 1))

                HStack(spacing: 8) {
                    onboardingBackButton { store.setOnboardingStep(2) }
                    onboardingCTAButton(title: "Next: Suggested Routines", trailing: "Step 4 →") {
                        store.setOnboardingStep(4)
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("STEP 4 OF 4 · 1-TAP SHORTCUTS")
                                .font(.system(size: 11, weight: .heavy))
                                .foregroundStyle(WFLTheme.mintText)
                            Spacer()
                            Button("Routines Page →") {
                                activeTab = .routines
                            }
                            .font(.system(size: 12, weight: .heavy))
                            .foregroundStyle(WFLTheme.accentDark)
                            .buttonStyle(.plain)
                        }
                        Text("Suggested Routines")
                            .font(.system(size: 20, weight: .heavy))
                            .foregroundStyle(WFLTheme.textPrimary)
                        Text("Tap to keep the repeated meals we spotted in Week 1 as 1-tap chips on your daily log:")
                            .font(.system(size: 12))
                            .foregroundStyle(WFLTheme.textMuted)
                    }

                    VStack(spacing: 8) {
                        ForEach(store.database.routines.prefix(4)) { r in
                            Button {
                                store.toggleRoutineActive(id: r.id)
                            } label: {
                                HStack(spacing: 9) {
                                    Text(r.icon)
                                        .font(.system(size: 16))
                                        .frame(width: 32, height: 32)
                                        .background(Color.white)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                    VStack(alignment: .leading, spacing: 1) {
                                        Text(r.name)
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundStyle(WFLTheme.textPrimary)
                                            .lineLimit(1)
                                        Text("\(r.frequency) · \(r.defaultTime)")
                                            .font(.system(size: 11))
                                            .foregroundStyle(WFLTheme.textMuted)
                                    }
                                    Spacer()
                                    Text(r.active ? "✓ Active" : "+ Add")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundStyle(r.active ? WFLTheme.mintText : WFLTheme.textMuted)
                                        .padding(.horizontal, 10)
                                        .frame(height: 26)
                                        .background(r.active ? WFLTheme.tintMint : Color.white)
                                        .clipShape(Capsule())
                                        .overlay(
                                            Capsule().stroke(r.active ? WFLTheme.tintMintBorder : WFLTheme.border, lineWidth: 1)
                                        )
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 9)
                                .background(r.active ? WFLTheme.tintMint : WFLTheme.subtleBg)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(r.active ? WFLTheme.tintMintBorder : WFLTheme.border, lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Spacer(minLength: 0)

                    Button {
                        activeTab = .routines
                    } label: {
                        Text("🔁 Open Full Routines Page")
                            .font(.system(size: 12, weight: .heavy))
                            .foregroundStyle(WFLTheme.accentDark)
                            .frame(maxWidth: .infinity)
                            .frame(height: 36)
                            .background(WFLTheme.tintPeach)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(WFLTheme.tintPeachBorder, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
                .padding(16)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 22))
                .overlay(RoundedRectangle(cornerRadius: 22).stroke(WFLTheme.border, lineWidth: 1))

                HStack(spacing: 8) {
                    onboardingBackButton { store.setOnboardingStep(3) }
                    onboardingCTAButton(title: "Finish Setup · Daily Log", trailing: "✓") {
                        activeTab = .log
                    }
                }
            }
        }
    }

    private func behaviourCard(
        title: String,
        subtitle: String,
        badge: String,
        bg: Color,
        border: Color,
        subColor: Color,
        badgeBg: Color,
        badgeFg: Color
    ) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .heavy))
                    .foregroundStyle(WFLTheme.textPrimary)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(subColor)
            }
            Spacer()
            Text(badge)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(badgeFg)
                .padding(.horizontal, 9)
                .frame(height: 24)
                .background(badgeBg)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(border, lineWidth: 1))
        }
        .padding(.horizontal, 13)
        .padding(.vertical, 12)
        .background(bg)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(border, lineWidth: 1))
    }

    private func onboardingBackButton(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text("← Back")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(WFLTheme.textPrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 13)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(WFLTheme.border, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private func onboardingCTAButton(title: String, trailing: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                Spacer()
                Text(trailing)
            }
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(Color.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
            .frame(maxWidth: .infinity)
            .background(WFLTheme.accentCoral)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: WFLTheme.accentCoral.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Routines View

    private var routinesView: some View {
        let activeRoutines = store.database.routines.filter(\.active)
        let suggestedRoutines = store.database.routines.filter { !$0.active }
        let catalogItems = Array(searchEngine.catalog.prefix(15))

        return ScrollView(showsIndicators: false) {
            VStack(spacing: 10) {
                // 1. Active Routines Card (Mint)
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Your Active Routines (\(activeRoutines.count))")
                            .font(.system(size: 13, weight: .heavy))
                            .foregroundStyle(WFLTheme.mintDarkText)
                        Spacer()
                        Text("Tap schedule/time to edit")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(WFLTheme.mintText)
                    }

                    if activeRoutines.isEmpty {
                        Text("No active routines yet. Add a suggested routine below.")
                            .font(.system(size: 12))
                            .foregroundStyle(WFLTheme.textMuted)
                    }

                    ForEach(activeRoutines) { r in
                        VStack(spacing: 7) {
                            HStack(spacing: 8) {
                                Text(r.icon)
                                    .font(.system(size: 16))
                                    .frame(width: 32, height: 32)
                                    .background(WFLTheme.tintMint)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(r.name)
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundStyle(WFLTheme.textPrimary)
                                        .lineLimit(1)
                                    Text("\(r.carbsG)C · \(r.proteinG)P · \(r.fatG)F · \(r.sugarG)Su · \(String(format: "%.1f", r.saltG))Sa")
                                        .font(.system(size: 11))
                                        .foregroundStyle(WFLTheme.textMuted)
                                }
                                Spacer()
                                Button {
                                    store.toggleRoutineActive(id: r.id)
                                } label: {
                                    Text("Remove")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(WFLTheme.textMuted)
                                        .padding(.horizontal, 8)
                                        .frame(height: 24)
                                        .background(Color.white)
                                        .clipShape(Capsule())
                                        .overlay(Capsule().stroke(WFLTheme.border, lineWidth: 1))
                                }
                                .buttonStyle(.plain)
                            }

                            Divider().overlay(WFLTheme.border)

                            HStack(spacing: 5) {
                                Button {
                                    store.cycleRoutineFrequency(id: r.id)
                                } label: {
                                    Text("📅 \(r.frequency)")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(WFLTheme.mintText)
                                        .padding(.horizontal, 8)
                                        .frame(height: 24)
                                        .background(WFLTheme.tintMint)
                                        .clipShape(Capsule())
                                        .overlay(Capsule().stroke(WFLTheme.tintMintBorder, lineWidth: 1))
                                }
                                .buttonStyle(.plain)

                                Button {
                                    store.cycleRoutineTime(id: r.id)
                                } label: {
                                    Text("🕒 \(r.defaultTime)")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(WFLTheme.textMuted)
                                        .padding(.horizontal, 8)
                                        .frame(height: 24)
                                        .background(Color.white)
                                        .clipShape(Capsule())
                                        .overlay(Capsule().stroke(WFLTheme.border, lineWidth: 1))
                                }
                                .buttonStyle(.plain)

                                Spacer()

                                Button {
                                    store.addFoodEntry(
                                        FoodLogEntry(
                                            icon: r.icon,
                                            name: r.name,
                                            timeLabel: r.defaultTime,
                                            carbsG: r.carbsG,
                                            proteinG: r.proteinG,
                                            fatG: r.fatG,
                                            sugarG: r.sugarG,
                                            saltG: r.saltG
                                        ),
                                        to: currentDateKey
                                    )
                                    activeTab = .log
                                } label: {
                                    Text("+ Log now")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(Color.white)
                                        .padding(.horizontal, 9)
                                        .frame(height: 24)
                                        .background(WFLTheme.accentCoral)
                                        .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(10)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(WFLTheme.tintMintBorder, lineWidth: 1))
                    }
                }
                .padding(13)
                .background(WFLTheme.tintMint)
                .clipShape(RoundedRectangle(cornerRadius: 22))
                .overlay(RoundedRectangle(cornerRadius: 22).stroke(WFLTheme.tintMintBorder, lineWidth: 1))

                // 2. Suggested from Your Week 1 Eating (Peach)
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Suggested from Your Week 1 Eating")
                            .font(.system(size: 13, weight: .heavy))
                            .foregroundStyle(WFLTheme.accentDark)
                        Spacer()
                        Text("1-tap add")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(WFLTheme.peachText)
                    }

                    if suggestedRoutines.isEmpty {
                        Text("All Week 1 suggested routines are active!")
                            .font(.system(size: 12))
                            .foregroundStyle(WFLTheme.peachText)
                    }

                    ForEach(suggestedRoutines) { r in
                        Button {
                            store.toggleRoutineActive(id: r.id)
                        } label: {
                            HStack(spacing: 8) {
                                Text(r.icon)
                                    .font(.system(size: 16))
                                    .frame(width: 32, height: 32)
                                    .background(WFLTheme.tintPeach)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(r.name)
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundStyle(WFLTheme.textPrimary)
                                        .lineLimit(1)
                                    Text("\(r.reason) · \(r.frequency)")
                                        .font(.system(size: 11))
                                        .foregroundStyle(WFLTheme.textMuted)
                                        .lineLimit(1)
                                }
                                Spacer()
                                Text("+ Add")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(Color.white)
                                    .padding(.horizontal, 9)
                                    .frame(height: 24)
                                    .background(WFLTheme.accentCoral)
                                    .clipShape(Capsule())
                            }
                            .padding(10)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(WFLTheme.tintPeachBorder, lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(13)
                .background(WFLTheme.tintPeach)
                .clipShape(RoundedRectangle(cornerRadius: 22))
                .overlay(RoundedRectangle(cornerRadius: 22).stroke(WFLTheme.tintPeachBorder, lineWidth: 1))

                // 3. Create Custom Routine Card
                if !catalogItems.isEmpty {
                    let safeIdx = max(0, min(newRoutineFoodIndex, catalogItems.count - 1))
                    let selectedFood = catalogItems[safeIdx]
                    let selectedFreq = freqOptions[newRoutineFreqIndex % freqOptions.count]

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Create a Routine")
                            .font(.system(size: 13, weight: .heavy))
                            .foregroundStyle(WFLTheme.textPrimary)

                        Button {
                            newRoutineFoodIndex = (newRoutineFoodIndex + 1) % catalogItems.count
                        } label: {
                            HStack {
                                Text("\(selectedFood.icon) \(selectedFood.name)")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(WFLTheme.textPrimary)
                                    .lineLimit(1)
                                Spacer()
                                Text("Tap to change ▾")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(WFLTheme.textMuted)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 9)
                            .background(WFLTheme.subtleBg)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(WFLTheme.border, lineWidth: 1))
                        }
                        .buttonStyle(.plain)

                        HStack(spacing: 6) {
                            Button {
                                newRoutineFreqIndex = (newRoutineFreqIndex + 1) % freqOptions.count
                            } label: {
                                HStack {
                                    Text("📅 \(selectedFreq)")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(WFLTheme.textPrimary)
                                    Spacer()
                                    Text("▾")
                                        .font(.system(size: 11))
                                        .foregroundStyle(WFLTheme.textMuted)
                                }
                                .padding(.horizontal, 12)
                                .frame(height: 36)
                                .background(WFLTheme.subtleBg)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(WFLTheme.border, lineWidth: 1))
                            }
                            .buttonStyle(.plain)

                            Button {
                                store.addCustomRoutine(from: selectedFood, frequency: selectedFreq)
                            } label: {
                                Text("+ Create")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(Color.white)
                                    .padding(.horizontal, 14)
                                    .frame(height: 36)
                                    .background(WFLTheme.accentCoral)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(13)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 22))
                    .overlay(RoundedRectangle(cornerRadius: 22).stroke(WFLTheme.border, lineWidth: 1))
                }
            }
        }
    }

    // MARK: - Review View (Days | Weeks | Years — Eating vs Weight)

    private var reviewView: some View {
        let stdLim = NutrientBreakdown(carbsG: 200, proteinG: 155, fatG: 65, sugarG: 45, saltG: 5.0)
        let daysDesc = store.allDaysDescending()
        let goalKg = store.database.profile.goalWeightKg

        let chartPoints: [ReviewChartPoint] = {
            switch reviewPeriod {
            case .days:
                return daysDesc.reversed().map { d in
                    let t = d.totalIntake
                    let lim = store.limits(for: d.dateKey)
                    return ReviewChartPoint(
                        label: d.displayLabel.replacingOccurrences(of: " Oct", with: ""),
                        weight: d.weightKg,
                        pcts: [
                            min(100, Int((Double(t.carbsG) / Double(max(1, lim.carbsG)) * 100.0).rounded())),
                            min(100, Int((Double(t.proteinG) / Double(max(1, lim.proteinG)) * 100.0).rounded())),
                            min(100, Int((Double(t.fatG) / Double(max(1, lim.fatG)) * 100.0).rounded())),
                            min(100, Int((Double(t.sugarG) / Double(max(1, lim.sugarG)) * 100.0).rounded())),
                            min(100, Int((t.saltG / max(0.1, lim.saltG) * 100.0).rounded()))
                        ]
                    )
                }
            case .weeks:
                return store.weeklyRollups().reversed().map { w in
                    let t = w.dailyAverageIntake
                    return ReviewChartPoint(
                        label: w.label.split(separator: " ").first.map(String.init) ?? w.label,
                        weight: w.averageWeightKg,
                        pcts: [
                            min(100, Int((Double(t.carbsG) / Double(stdLim.carbsG) * 100.0).rounded())),
                            min(100, Int((Double(t.proteinG) / Double(stdLim.proteinG) * 100.0).rounded())),
                            min(100, Int((Double(t.fatG) / Double(stdLim.fatG) * 100.0).rounded())),
                            min(100, Int((Double(t.sugarG) / Double(stdLim.sugarG) * 100.0).rounded())),
                            min(100, Int((t.saltG / stdLim.saltG * 100.0).rounded()))
                        ]
                    )
                }
            case .years:
                return store.yearlyRollups().reversed().map { y in
                    let t = y.dailyAverageIntake
                    return ReviewChartPoint(
                        label: String(y.label.prefix(4)),
                        weight: y.averageWeightKg,
                        pcts: [
                            min(100, Int((Double(t.carbsG) / Double(stdLim.carbsG) * 100.0).rounded())),
                            min(100, Int((Double(t.proteinG) / Double(stdLim.proteinG) * 100.0).rounded())),
                            min(100, Int((Double(t.fatG) / Double(stdLim.fatG) * 100.0).rounded())),
                            min(100, Int((Double(t.sugarG) / Double(stdLim.sugarG) * 100.0).rounded())),
                            min(100, Int((t.saltG / stdLim.saltG * 100.0).rounded()))
                        ]
                    )
                }
            }
        }()

        let chartTitle: String = {
            switch reviewPeriod {
            case .days: return "Eating vs Weight (Past 7 Days)"
            case .weeks: return "Weekly Average Intake vs Avg Weight"
            case .years: return "Yearly Average Intake vs Avg Weight"
            }
        }()

        let chartDelta: String = {
            switch reviewPeriod {
            case .days:
                let diff = (daysDesc.first?.weightKg ?? 85.4) - (daysDesc.last?.weightKg ?? 86.4)
                return String(format: "%+.1f kg · Goal %.1f kg", diff, goalKg)
            case .weeks:
                return String(format: "-2.6 kg in 5 wks · Goal %.1f kg", goalKg)
            case .years:
                return String(format: "-8.7 kg total · Goal %.1f kg", goalKg)
            }
        }()

        return VStack(spacing: 10) {
            // Custom 3-Segment Period Switcher
            HStack(spacing: 4) {
                ForEach(WFLReviewPeriod.allCases, id: \.self) { p in
                    Button {
                        reviewPeriod = p
                    } label: {
                        Text(p.rawValue)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(reviewPeriod == p ? WFLTheme.textPrimary : WFLTheme.textMuted)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                            .background(reviewPeriod == p ? Color.white : Color.clear)
                            .clipShape(RoundedRectangle(cornerRadius: 11))
                            .shadow(color: reviewPeriod == p ? Color.black.opacity(0.06) : .clear, radius: 4, x: 0, y: 2)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(3)
            .background(WFLTheme.segTrackBg)
            .clipShape(RoundedRectangle(cornerRadius: 14))

            // Dribbble "Activities"-Inspired Chart Card
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(chartTitle)
                        .font(.system(size: 13, weight: .heavy))
                        .foregroundStyle(WFLTheme.textPrimary)
                        .lineLimit(1)
                    Spacer()
                    Text(chartDelta)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(WFLTheme.accentCoral)
                        .clipShape(Capsule())
                }

                ReviewTrendChartView(points: chartPoints)
                    .frame(height: 112)

                HStack {
                    HStack(spacing: 3) {
                        Text("●").foregroundStyle(WFLTheme.accentCoral)
                        Text("Weight (kg)").foregroundStyle(WFLTheme.textMuted)
                    }
                    Spacer()
                    HStack(spacing: 6) {
                        HStack(spacing: 2) { Text("●").foregroundStyle(WFLTheme.carbs); Text("Carbs") }
                        HStack(spacing: 2) { Text("●").foregroundStyle(WFLTheme.protein); Text("Protein") }
                        HStack(spacing: 2) { Text("●").foregroundStyle(WFLTheme.fat); Text("Fat") }
                        HStack(spacing: 2) { Text("●").foregroundStyle(WFLTheme.sugar); Text("Sugar") }
                        HStack(spacing: 2) { Text("●").foregroundStyle(WFLTheme.salt); Text("Salt") }
                    }
                    .foregroundStyle(WFLTheme.textMuted)
                }
                .font(.system(size: 10, weight: .bold))
            }
            .padding(13)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 22))
            .overlay(RoundedRectangle(cornerRadius: 22).stroke(WFLTheme.border, lineWidth: 1))

            // Historical Comparison Rows
            ScrollView(showsIndicators: false) {
                VStack(spacing: 7) {
                    if reviewPeriod == .days {
                        ForEach(Array(daysDesc.enumerated()), id: \.element.id) { idx, day in
                            let prev = (idx + 1 < daysDesc.count) ? daysDesc[idx + 1] : nil
                            let diff = prev != nil ? (day.weightKg - prev!.weightKg) : 0.0
                            VStack(alignment: .leading, spacing: 7) {
                                HStack {
                                    HStack(spacing: 6) {
                                        Text(day.displayLabel)
                                            .font(.system(size: 13, weight: .heavy))
                                            .foregroundStyle(WFLTheme.textPrimary)
                                        if day.heavyExercise {
                                            Text("🔥")
                                                .font(.system(size: 11))
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 1)
                                                .background(WFLTheme.tintMint)
                                                .clipShape(Capsule())
                                        }
                                        if day.ateTooMuch {
                                            Text("😮‍💨")
                                                .font(.system(size: 11))
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 1)
                                                .background(WFLTheme.tintBlush)
                                                .clipShape(Capsule())
                                        }
                                    }
                                    Spacer()
                                    HStack(spacing: 8) {
                                        Text(String(format: "%+.1f kg", diff))
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundStyle(WFLTheme.textMuted)
                                        Text(String(format: "%.1f kg", day.weightKg))
                                            .font(.system(size: 12, weight: .heavy))
                                            .foregroundStyle(WFLTheme.accentDark)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 2)
                                            .background(WFLTheme.tintPeach)
                                            .clipShape(Capsule())
                                    }
                                }
                                reviewNutrientFooter(day.totalIntake, limits: store.limits(for: day.dateKey), isAverage: false)
                            }
                            .padding(.horizontal, 13)
                            .padding(.vertical, 11)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                            .overlay(RoundedRectangle(cornerRadius: 18).stroke(WFLTheme.border, lineWidth: 1))
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedDateIndex = idx
                                activeTab = .log
                            }
                        }
                    } else {
                        let rollups = (reviewPeriod == .weeks) ? store.weeklyRollups() : store.yearlyRollups()
                        ForEach(rollups) { item in
                            VStack(alignment: .leading, spacing: 7) {
                                HStack(alignment: .top) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(item.label)
                                            .font(.system(size: 13, weight: .heavy))
                                            .foregroundStyle(WFLTheme.textPrimary)
                                        Text(item.note)
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundStyle(WFLTheme.textMuted)
                                    }
                                    Spacer()
                                    VStack(alignment: .trailing, spacing: 2) {
                                        Text(String(format: "Avg %.1f kg", item.averageWeightKg))
                                            .font(.system(size: 12, weight: .heavy))
                                            .foregroundStyle(WFLTheme.accentDark)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 2)
                                            .background(WFLTheme.tintPeach)
                                            .clipShape(Capsule())
                                        Text(item.deltaLabel)
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundStyle(WFLTheme.textMuted)
                                    }
                                }
                                reviewNutrientFooter(item.dailyAverageIntake, limits: stdLim, isAverage: true)
                            }
                            .padding(.horizontal, 13)
                            .padding(.vertical, 11)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                            .overlay(RoundedRectangle(cornerRadius: 18).stroke(WFLTheme.border, lineWidth: 1))
                        }
                    }
                }
            }
        }
    }

    private func reviewNutrientFooter(_ vals: NutrientBreakdown, limits: NutrientBreakdown, isAverage: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            if isAverage {
                Divider().overlay(WFLTheme.border)
                HStack {
                    Text("Daily Average Intake")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(WFLTheme.textPrimary)
                    Spacer()
                    Text("Avg / day vs limit")
                        .font(.system(size: 11))
                        .foregroundStyle(WFLTheme.textMuted)
                }
            }
            HStack(spacing: 6) {
                reviewMiniBar(short: "C", valStr: "\(vals.carbsG)g", val: Double(vals.carbsG), max: Double(limits.carbsG), maxStr: "\(limits.carbsG)g", color: WFLTheme.carbs, track: WFLTheme.carbsTrack, isAverage: isAverage)
                reviewMiniBar(short: "P", valStr: "\(vals.proteinG)g", val: Double(vals.proteinG), max: Double(limits.proteinG), maxStr: "\(limits.proteinG)g", color: WFLTheme.protein, track: WFLTheme.proteinTrack, isAverage: isAverage)
                reviewMiniBar(short: "F", valStr: "\(vals.fatG)g", val: Double(vals.fatG), max: Double(limits.fatG), maxStr: "\(limits.fatG)g", color: WFLTheme.fat, track: WFLTheme.fatTrack, isAverage: isAverage)
                reviewMiniBar(short: "Su", valStr: "\(vals.sugarG)g", val: Double(vals.sugarG), max: Double(limits.sugarG), maxStr: "\(limits.sugarG)g", color: WFLTheme.sugar, track: WFLTheme.sugarTrack, isAverage: isAverage)
                reviewMiniBar(short: "Sa", valStr: String(format: "%.1fg", vals.saltG), val: vals.saltG, max: limits.saltG, maxStr: String(format: "%.1fg", limits.saltG), color: WFLTheme.salt, track: WFLTheme.saltTrack, isAverage: isAverage)
            }
        }
    }

    private func reviewMiniBar(
        short: String,
        valStr: String,
        val: Double,
        max: Double,
        maxStr: String,
        color: Color,
        track: Color,
        isAverage: Bool
    ) -> some View {
        let pct = min(100, Int(((val / Swift.max(0.1, max)) * 100.0).rounded()))
        return VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 2) {
                Text(short)
                    .font(.system(size: 11, weight: .heavy))
                    .foregroundStyle(color)
                Spacer(minLength: 1)
                Text(valStr)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(WFLTheme.textPrimary)
                    .lineLimit(1)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(track)
                    Capsule().fill(color).frame(width: geo.size.width * CGFloat(pct) / 100.0)
                }
            }
            .frame(height: 6)
            Text(isAverage ? "Avg · \(pct)%" : "\(pct)% of \(maxStr)")
                .font(.system(size: 9.5, weight: .semibold))
                .foregroundStyle(WFLTheme.textMuted)
                .lineLimit(1)
        }
    }

    // MARK: - Floating White Capsule Bottom Dock

    private var bottomCapsuleDock: some View {
        HStack(spacing: 4) {
            ForEach(WFLTab.allCases, id: \.self) { tab in
                Button {
                    activeTab = tab
                } label: {
                    Text(tab.dockLabel)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(activeTab == tab ? WFLTheme.accentDark : WFLTheme.textMuted)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(activeTab == tab ? WFLTheme.tintPeach : Color.clear)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 5)
        .background(Color.white)
        .clipShape(Capsule())
        .overlay(
            Capsule().stroke(WFLTheme.border, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
    }
}

// MARK: - Dribbble-Inspired Semi-Circular Weight Arc Gauge

private struct WeightArcGauge: View {
    let progress: Double

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let radius = min(w * 0.42, h * 0.78)
            let center = CGPoint(x: w / 2.0, y: h * 0.85)

            ZStack {
                Path { path in
                    path.addArc(
                        center: center,
                        radius: radius,
                        startAngle: .degrees(180),
                        endAngle: .degrees(360),
                        clockwise: false
                    )
                }
                .stroke(WFLTheme.gaugeTrack, style: StrokeStyle(lineWidth: 7, lineCap: .round))

                Path { path in
                    path.addArc(
                        center: center,
                        radius: radius,
                        startAngle: .degrees(180),
                        endAngle: .degrees(180.0 + 180.0 * max(0.05, min(1.0, progress))),
                        clockwise: false
                    )
                }
                .stroke(WFLTheme.accentCoral, style: StrokeStyle(lineWidth: 7, lineCap: .round))

                Circle()
                    .fill(WFLTheme.textPrimary)
                    .frame(width: 7, height: 7)
                    .position(x: center.x, y: center.y - 4)
            }
        }
    }
}

// MARK: - Dribbble "Activities"-Inspired Eating vs Weight Trend Chart

private struct ReviewChartPoint: Identifiable {
    let id = UUID()
    let label: String
    let weight: Double
    let pcts: [Int]
}

private struct ReviewTrendChartView: View {
    let points: [ReviewChartPoint]

    private let barColors: [Color] = [
        WFLTheme.carbs,
        WFLTheme.protein,
        WFLTheme.fat,
        WFLTheme.sugar,
        WFLTheme.salt
    ]

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let baselineY = h - 18.0
            let weights = points.map(\.weight)
            let minW = (weights.min() ?? 84.0) - 0.5
            let maxW = (weights.max() ?? 87.0) + 0.5
            let stepX = w / CGFloat(max(1, points.count))

            let coords: [CGPoint] = points.enumerated().map { idx, p in
                let x = CGFloat(idx) * stepX + stepX * 0.5
                let norm = (p.weight - minW) / max(0.1, maxW - minW)
                let y = baselineY - 6.0 - CGFloat(norm) * (h - 42.0)
                return CGPoint(x: x, y: y)
            }

            ZStack {
                // Baseline
                Path { path in
                    path.move(to: CGPoint(x: 0, y: baselineY))
                    path.addLine(to: CGPoint(x: w, y: baselineY))
                }
                .stroke(WFLTheme.border, lineWidth: 1)

                // 5 Nutrient Bars per Point
                ForEach(Array(points.enumerated()), id: \.element.id) { idx, p in
                    let groupWidth = min(28.0, stepX * 0.65)
                    let startX = CGFloat(idx) * stepX + (stepX - groupWidth) / 2.0
                    let bw = groupWidth / 5.0

                    ForEach(0..<min(5, p.pcts.count), id: \.self) { bi in
                        let pct = p.pcts[bi]
                        let barH = max(3.0, CGFloat(pct) / 100.0 * 52.0)
                        let x = startX + CGFloat(bi) * bw
                        RoundedRectangle(cornerRadius: 2)
                            .fill(barColors[bi].opacity(0.38))
                            .frame(width: max(2.2, bw - 1.0), height: barH)
                            .position(x: x + bw * 0.5, y: baselineY - barH * 0.5)
                    }
                }

                // Coral Area Fill under Weight Curve
                if coords.count > 1 {
                    Path { path in
                        path.move(to: CGPoint(x: coords[0].x, y: baselineY))
                        for pt in coords {
                            path.addLine(to: pt)
                        }
                        path.addLine(to: CGPoint(x: coords[coords.count - 1].x, y: baselineY))
                        path.closeSubpath()
                    }
                    .fill(
                        LinearGradient(
                            colors: [WFLTheme.accentCoral.opacity(0.26), WFLTheme.accentCoral.opacity(0.0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                    // Coral Weight Line
                    Path { path in
                        path.move(to: coords[0])
                        for pt in coords.dropFirst() {
                            path.addLine(to: pt)
                        }
                    }
                    .stroke(WFLTheme.accentCoral, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                }

                // Weight Nodes & Labels
                ForEach(Array(points.enumerated()), id: \.element.id) { idx, p in
                    let pt = coords[idx]
                    Circle()
                        .fill(Color.white)
                        .frame(width: 8, height: 8)
                        .overlay(Circle().stroke(WFLTheme.accentCoral, lineWidth: 2.5))
                        .position(pt)

                    Text(String(format: "%.1f", p.weight))
                        .font(.system(size: 10, weight: .heavy))
                        .foregroundStyle(WFLTheme.textPrimary)
                        .position(x: pt.x, y: max(8, pt.y - 11))

                    Text(String(p.label.prefix(6)))
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(WFLTheme.textMuted)
                        .position(x: pt.x, y: h - 7)
                }
            }
        }
    }
}
