import SwiftUI
import WeightingForLifeCore

@main
struct WeightingForLifeApp: App {
    var body: some Scene {
        WindowGroup {
            WeightingForLifeRootView()
                .preferredColorScheme(.light)
        }
    }
}
