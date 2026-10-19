import SwiftUI

/// Dribbble 19193291 Inspired Pastel Light Palette
public enum WFLTheme {
    public static let canvasBg = Color(red: 0.969, green: 0.973, blue: 0.984)     // #f7f8fb
    public static let cardBg = Color.white
    public static let border = Color(red: 0.925, green: 0.933, blue: 0.961)       // #eceef5
    public static let textPrimary = Color(red: 0.098, green: 0.110, blue: 0.149)  // #191c26
    public static let textMuted = Color(red: 0.494, green: 0.518, blue: 0.592)    // #7e8497

    // Pastel Surface Tints
    public static let tintPeach = Color(red: 0.992, green: 0.925, blue: 0.902)    // #fdece6
    public static let tintCream = Color(red: 0.996, green: 0.969, blue: 0.902)    // #fef7e6
    public static let tintMint  = Color(red: 0.918, green: 0.973, blue: 0.902)    // #eaf8e6
    public static let tintBlush = Color(red: 0.988, green: 0.918, blue: 0.949)    // #fceaf2

    // Dedicated Nutrient Colors (Never turn red at 100%)
    public static let carbs   = Color(red: 0.882, green: 0.188, blue: 0.549)      // #e1308c
    public static let protein = Color(red: 0.478, green: 0.780, blue: 0.122)      // #7ac71f
    public static let fat     = Color(red: 0.439, green: 0.000, blue: 0.875)      // #7000df
    public static let sugar   = Color(red: 0.957, green: 0.510, blue: 0.396)      // #f48265
    public static let salt    = Color(red: 0.169, green: 0.604, blue: 0.953)      // #2b9af3

    public static let accentCoral = Color(red: 0.957, green: 0.510, blue: 0.396)  // #f48265
}

public enum WFLTab: String, CaseIterable, Sendable {
    case onboarding = "Setup"
    case log = "Today"
    case routines = "Routines"
    case review = "Review"
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
    @State private var searchQuery: String = ""
    @State private var matchLimit: Int = 10
    @State private var reviewPeriod: WFLReviewPeriod = .days
    private let searchEngine = NZFCDSearchEngine()

    public init(store: FoodAndWeightStore = FoodAndWeightStore()) {
        _store = State(initialValue: store)
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

    public var body: some View {
        VStack(spacing: 12) {
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

            bottomCapsuleDock
        }
        .padding(16)
        .background(WFLTheme.canvasBg)
    }

    // MARK: - Single-Line Height-Locked Header Bar

    private var headerBar: some View {
        HStack(spacing: 6) {
            HStack(spacing: 4) {
                Button {
                    let maxIdx = max(0, store.database.dateIndexDesc.count - 1)
                    if selectedDateIndex < maxIdx {
                        selectedDateIndex += 1
                        activeTab = .log
                    }
                } label: {
                    Text("‹")
                        .font(.system(size: 13, weight: .bold))
                        .frame(width: 24, height: 24)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)

                Text(currentDay.displayLabel)
                    .font(.system(size: 13, weight: .heavy))
                    .lineLimit(1)
                    .frame(width: 72)

                Button {
                    if selectedDateIndex > 0 {
                        selectedDateIndex -= 1
                        activeTab = .log
                    }
                } label: {
                    Text("›")
                        .font(.system(size: 13, weight: .bold))
                        .frame(width: 24, height: 24)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .opacity(selectedDateIndex == 0 ? 0.35 : 1.0)
                }
                .buttonStyle(.plain)
            }

            Spacer(minLength: 4)

            HStack(spacing: 4) {
                Button {
                    weightDrawerOpen.toggle()
                } label: {
                    Text(String(format: "⚖️ %.1fkg", currentDay.weightKg))
                        .font(.system(size: 12, weight: .bold))
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                        .padding(.horizontal, 9)
                        .frame(height: 28)
                        .background(WFLTheme.tintCream)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)

                Button {
                    store.toggleHeavyExercise(for: currentDateKey)
                } label: {
                    Text(currentDay.heavyExercise ? "🔥 Exercise" : "Normal")
                        .font(.system(size: 12, weight: .bold))
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                        .padding(.horizontal, 9)
                        .frame(height: 28)
                        .background(currentDay.heavyExercise ? WFLTheme.tintMint : Color.white)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)

                Button {
                    activeTab = (activeTab == .log) ? .review : .log
                } label: {
                    Text(activeTab == .log ? "Review" : "← Log")
                        .font(.system(size: 12, weight: .bold))
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                        .padding(.horizontal, 9)
                        .frame(height: 28)
                        .background(activeTab == .log ? Color.white : WFLTheme.accentCoral)
                        .foregroundStyle(activeTab == .log ? WFLTheme.textMuted : Color.white)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .frame(height: 30)
    }

    // MARK: - Butter-Cream Weight Drawer (Current & Goal Sliders)

    private var weightDrawer: some View {
        let isLocked = (activeTab == .onboarding && store.database.profile.onboardingStep < 3)
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("MY WEIGHT (\(currentDay.displayLabel.uppercased()))")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(WFLTheme.textMuted)
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text(String(format: "%.1f kg", currentDay.weightKg))
                            .font(.system(size: 20, weight: .heavy))
                        Text(isLocked ? "Wk 1 Baseline" : String(format: "Goal %.1f kg", store.database.profile.goalWeightKg))
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(WFLTheme.textMuted)
                    }
                }
                Spacer()
                HStack(spacing: 6) {
                    Button("-0.1") { store.setWeight(currentDay.weightKg - 0.1, for: currentDateKey) }
                        .buttonStyle(.bordered)
                    Button("+0.1") { store.setWeight(currentDay.weightKg + 0.1, for: currentDateKey) }
                        .buttonStyle(.bordered)
                }
            }

            HStack {
                Text("Current")
                    .font(.system(size: 12, weight: .bold))
                    .frame(width: 58, alignment: .leading)
                Slider(
                    value: Binding(
                        get: { currentDay.weightKg },
                        set: { store.setWeight($0, for: currentDateKey) }
                    ),
                    in: 50...130,
                    step: 0.1
                )
            }

            if !isLocked {
                HStack {
                    Text("Goal")
                        .font(.system(size: 12, weight: .bold))
                        .frame(width: 58, alignment: .leading)
                    Slider(
                        value: Binding(
                            get: { store.database.profile.goalWeightKg },
                            set: { store.setGoalWeight($0) }
                        ),
                        in: 50...130,
                        step: 0.5
                    )
                    Text(String(format: "%.1f kg", store.database.profile.goalWeightKg))
                        .font(.system(size: 12, weight: .bold))
                        .frame(width: 52, alignment: .trailing)
                }
            } else {
                HStack {
                    Text("🔒 Goal weight unlocks after Week 1 baseline")
                        .font(.system(size: 11, weight: .semibold))
                    Spacer()
                }
            }
        }
        .padding(12)
        .background(WFLTheme.tintCream)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    // MARK: - 4 Clean Step Onboarding Pages

    private var onboardingStepView: some View {
        let step = store.database.profile.onboardingStep
        return VStack(spacing: 12) {
            Picker("Setup Step", selection: Binding(
                get: { store.database.profile.onboardingStep },
                set: { store.setOnboardingStep($0) }
            )) {
                Text("1 · Week 1").tag(1)
                Text("2 · Habits").tag(2)
                Text("3 · Goal").tag(3)
                Text("4 · Routines").tag(4)
            }
            .pickerStyle(.segmented)

            VStack(alignment: .leading, spacing: 14) {
                if step == 1 {
                    Text("STEP 1 OF 4 · WEEK 1 BASELINE")
                        .font(.system(size: 11, weight: .heavy))
                        .foregroundStyle(WFLTheme.accentCoral)
                    Text("Record 1 week of normal eating first")
                        .font(.system(size: 20, weight: .heavy))
                    Text("Log what you normally eat plus your Current Weight each day. We wait until Day 7 before asking for a Goal Weight.")
                        .font(.system(size: 13))
                        .foregroundStyle(WFLTheme.textMuted)
                } else if step == 2 {
                    Text("STEP 2 OF 4 · BEHAVIOURS LEARNED")
                        .font(.system(size: 11, weight: .heavy))
                        .foregroundStyle(WFLTheme.accentCoral)
                    Text("What we noticed in Week 1")
                        .font(.system(size: 20, weight: .heavy))
                    Text("☕ Morning Flat White (6/7 mornings)\n🥚 High-Protein Breakfasts (5/7 days)\n🍟 Saturday Takeaway Spike (Balance)")
                        .font(.system(size: 13, weight: .semibold))
                } else if step == 3 {
                    Text("STEP 3 OF 4 · GOAL UNLOCKED")
                        .font(.system(size: 11, weight: .heavy))
                        .foregroundStyle(WFLTheme.accentCoral)
                    Text("Set your Goal Weight")
                        .font(.system(size: 20, weight: .heavy))
                    Text(String(format: "Target Goal: %.1f kg (Current: %.1f kg)", store.database.profile.goalWeightKg, currentDay.weightKg))
                        .font(.system(size: 16, weight: .bold))
                    Slider(
                        value: Binding(
                            get: { store.database.profile.goalWeightKg },
                            set: { store.setGoalWeight($0) }
                        ),
                        in: 55...115,
                        step: 0.5
                    )
                } else {
                    Text("STEP 4 OF 4 · 1-TAP SHORTCUTS")
                        .font(.system(size: 11, weight: .heavy))
                        .foregroundStyle(WFLTheme.protein)
                    Text("Suggested Routines")
                        .font(.system(size: 20, weight: .heavy))
                    ForEach(store.database.routines.prefix(4)) { r in
                        Button {
                            store.toggleRoutineActive(id: r.id)
                        } label: {
                            HStack {
                                Text("\(r.icon) \(r.name)")
                                    .font(.system(size: 13, weight: .bold))
                                Spacer()
                                Text(r.active ? "✓ Active" : "+ Add")
                                    .font(.system(size: 12, weight: .bold))
                            }
                            .padding(8)
                            .background(r.active ? WFLTheme.tintMint : Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 22))

            HStack {
                if step > 1 {
                    Button("← Back") { store.setOnboardingStep(step - 1) }
                        .buttonStyle(.bordered)
                }
                Spacer()
                Button(step < 4 ? "Next · Step \(step + 1) →" : "Finish Setup · Daily Log ✓") {
                    if step < 4 {
                        store.setOnboardingStep(step + 1)
                    } else {
                        activeTab = .log
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(WFLTheme.accentCoral)
            }
        }
    }

    // MARK: - Daily Log View

    private var dailyLogView: some View {
        let totals = currentDay.totalIntake
        let limits = store.limits(for: currentDateKey)
        let matches = searchEngine.search(searchQuery, limit: matchLimit)

        return VStack(spacing: 10) {
            // 1. Indicative 5-Nutrient Strip (Never turns red)
            Button {
                intakeExpanded.toggle()
            } label: {
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        nutrientMiniBar("Carbs", val: Double(totals.carbsG), max: Double(limits.carbsG), color: WFLTheme.carbs)
                        nutrientMiniBar("Protein", val: Double(totals.proteinG), max: Double(limits.proteinG), color: WFLTheme.protein)
                        nutrientMiniBar("Fat", val: Double(totals.fatG), max: Double(limits.fatG), color: WFLTheme.fat)
                        nutrientMiniBar("Sugar", val: Double(totals.sugarG), max: Double(limits.sugarG), color: WFLTheme.sugar)
                        nutrientMiniBar("Salt", val: totals.saltG, max: limits.saltG, color: WFLTheme.salt)
                    }
                    if intakeExpanded {
                        Divider()
                        HStack {
                            Text("\(totals.carbsG)/\(limits.carbsG)g C")
                            Spacer()
                            Text("\(totals.proteinG)/\(limits.proteinG)g P")
                            Spacer()
                            Text("\(totals.fatG)/\(limits.fatG)g F")
                            Spacer()
                            Text("\(totals.sugarG)/\(limits.sugarG)g Su")
                            Spacer()
                            Text(String(format: "%.1f/%.1fg Sa", totals.saltG, limits.saltG))
                        }
                        .font(.system(size: 11, weight: .bold))
                    }
                }
                .padding(12)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 20))
            }
            .buttonStyle(.plain)

            // 2. Soft Peach Search + Ranked NZFCD Matches + 1-Tap Routines
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    TextField("Add food (e.g. poached egg, vogels, pie)...", text: $searchQuery)
                        .textFieldStyle(.roundedBorder)
                    Button(matchLimit == 10 ? "Top 10" : "Top 25") {
                        matchLimit = (matchLimit == 10) ? 25 : 10
                    }
                    .font(.system(size: 11, weight: .bold))
                }

                if !matches.isEmpty {
                    ScrollView {
                        VStack(spacing: 4) {
                            ForEach(matches) { m in
                                Button {
                                    store.addFoodEntry(
                                        FoodLogEntry(
                                            icon: m.item.icon,
                                            name: m.item.name,
                                            timeLabel: "Now",
                                            carbsG: m.item.carbsG,
                                            proteinG: m.item.proteinG,
                                            fatG: m.item.fatG,
                                            sugarG: m.item.sugarG,
                                            saltG: m.item.saltG
                                        ),
                                        to: currentDateKey
                                    )
                                    searchQuery = ""
                                } label: {
                                    HStack {
                                        Text("\(m.rank). \(m.item.icon) \(m.item.name)")
                                            .font(.system(size: 12, weight: .semibold))
                                            .lineLimit(1)
                                        Spacer()
                                        Text("+")
                                            .font(.system(size: 14, weight: .heavy))
                                            .foregroundStyle(WFLTheme.accentCoral)
                                    }
                                    .padding(6)
                                    .background(Color.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .frame(maxHeight: 160)
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(store.database.routines.filter(\.active)) { r in
                            Button("\(r.icon) \(r.shortLabel)") {
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
                            }
                            .font(.system(size: 12, weight: .semibold))
                            .buttonStyle(.bordered)
                        }
                    }
                }
            }
            .padding(12)
            .background(WFLTheme.tintPeach)
            .clipShape(RoundedRectangle(cornerRadius: 20))

            // 3. Recorded Weight + Food Entries List
            ScrollView {
                VStack(spacing: 6) {
                    HStack {
                        Text(String(format: "⚖️ Recorded weight (%@): %.1f kg", currentDay.displayLabel, currentDay.weightKg))
                            .font(.system(size: 12, weight: .bold))
                        Spacer()
                        Text(String(format: "Goal %.1f kg", store.database.profile.goalWeightKg))
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(WFLTheme.textMuted)
                    }
                    .padding(10)
                    .background(WFLTheme.tintCream)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    ForEach(currentDay.entries) { entry in
                        HStack {
                            Text("\(entry.icon) \(entry.name)")
                                .font(.system(size: 13, weight: .semibold))
                            Spacer()
                            Text(entry.timeLabel)
                                .font(.system(size: 11))
                                .foregroundStyle(WFLTheme.textMuted)
                            Button("×") {
                                store.removeFoodEntry(id: entry.id, from: currentDateKey)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(10)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
            }

            // 4. Bottom "I ate too much today" Rebalance Button
            Button {
                store.toggleAteTooMuch(for: currentDateKey)
            } label: {
                HStack {
                    Text(currentDay.ateTooMuch ? "✓ Next day's limits rebalanced (-15%)" : "😮‍💨 I ate too much today")
                        .font(.system(size: 12, weight: .bold))
                    Spacer()
                    Text(currentDay.ateTooMuch ? "Undo" : "Balance tomorrow")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(WFLTheme.accentCoral)
                }
                .padding(11)
                .background(currentDay.ateTooMuch ? WFLTheme.tintBlush : Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)
        }
    }

    private func nutrientMiniBar(_ title: String, val: Double, max: Double, color: Color) -> some View {
        let pct = min(100, Int(((val / Swift.max(0.1, max)) * 100.0).rounded()))
        return VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(WFLTheme.textMuted)
            Text("\(pct)%")
                .font(.system(size: 12, weight: .heavy))
                .foregroundStyle(WFLTheme.textPrimary)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(color.opacity(0.2))
                    Capsule().fill(color).frame(width: geo.size.width * CGFloat(pct) / 100.0)
                }
            }
            .frame(height: 6)
        }
    }

    // MARK: - Routines View

    private var routinesView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                Text("Your Routines")
                    .font(.system(size: 16, weight: .heavy))
                ForEach(store.database.routines) { r in
                    HStack {
                        Text("\(r.icon) \(r.name)")
                            .font(.system(size: 13, weight: .bold))
                        Spacer()
                        Button(r.active ? "Active" : "+ Add") {
                            store.toggleRoutineActive(id: r.id)
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(10)
                    .background(r.active ? WFLTheme.tintMint : Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
        }
    }

    // MARK: - Review View (Days | Weeks | Years — Eating vs Weight)

    private var reviewView: some View {
        VStack(spacing: 10) {
            Picker("Period", selection: $reviewPeriod) {
                ForEach(WFLReviewPeriod.allCases, id: \.self) { p in
                    Text(p.rawValue).tag(p)
                }
            }
            .pickerStyle(.segmented)

            ScrollView {
                VStack(spacing: 8) {
                    if reviewPeriod == .days {
                        ForEach(Array(store.allDaysDescending().enumerated()), id: \.element.id) { idx, day in
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(day.displayLabel).font(.system(size: 13, weight: .bold))
                                    Spacer()
                                    Text(String(format: "%.1f kg", day.weightKg))
                                        .font(.system(size: 12, weight: .heavy))
                                        .foregroundStyle(WFLTheme.accentCoral)
                                }
                                reviewNutrientRow(day.totalIntake, limits: store.limits(for: day.dateKey), isAverage: false)
                            }
                            .padding(11)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .onTapGesture {
                                selectedDateIndex = idx
                                activeTab = .log
                            }
                        }
                    } else {
                        let rollups = (reviewPeriod == .weeks) ? store.weeklyRollups() : store.yearlyRollups()
                        let stdLim = NutrientBreakdown(carbsG: 200, proteinG: 155, fatG: 65, sugarG: 45, saltG: 5.0)
                        ForEach(rollups) { item in
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(item.label).font(.system(size: 13, weight: .bold))
                                        Text(item.note).font(.system(size: 11)).foregroundStyle(WFLTheme.textMuted)
                                    }
                                    Spacer()
                                    Text(String(format: "Avg %.1f kg", item.averageWeightKg))
                                        .font(.system(size: 12, weight: .heavy))
                                        .foregroundStyle(WFLTheme.accentCoral)
                                }
                                Text("Daily Average Intake")
                                    .font(.system(size: 11, weight: .bold))
                                reviewNutrientRow(item.dailyAverageIntake, limits: stdLim, isAverage: true)
                            }
                            .padding(11)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                    }
                }
            }
        }
    }

    private func reviewNutrientRow(_ vals: NutrientBreakdown, limits: NutrientBreakdown, isAverage: Bool) -> some View {
        HStack(spacing: 6) {
            nutrientMiniBar(isAverage ? "Avg C" : "C", val: Double(vals.carbsG), max: Double(limits.carbsG), color: WFLTheme.carbs)
            nutrientMiniBar(isAverage ? "Avg P" : "P", val: Double(vals.proteinG), max: Double(limits.proteinG), color: WFLTheme.protein)
            nutrientMiniBar(isAverage ? "Avg F" : "F", val: Double(vals.fatG), max: Double(limits.fatG), color: WFLTheme.fat)
            nutrientMiniBar(isAverage ? "Avg Su" : "Su", val: Double(vals.sugarG), max: Double(limits.sugarG), color: WFLTheme.sugar)
            nutrientMiniBar(isAverage ? "Avg Sa" : "Sa", val: vals.saltG, max: limits.saltG, color: WFLTheme.salt)
        }
    }

    // MARK: - Floating White Capsule Bottom Dock

    private var bottomCapsuleDock: some View {
        HStack(spacing: 4) {
            ForEach(WFLTab.allCases, id: \.self) { tab in
                Button {
                    activeTab = tab
                } label: {
                    Text(tab.rawValue)
                        .font(.system(size: 11, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 7)
                        .background(activeTab == tab ? WFLTheme.tintPeach : Color.clear)
                        .foregroundStyle(activeTab == tab ? WFLTheme.accentCoral : WFLTheme.textMuted)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(5)
        .background(Color.white)
        .clipShape(Capsule())
    }
}
