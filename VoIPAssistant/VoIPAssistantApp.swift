import SwiftUI

@main
struct VoIPAssistantApp: App {
    init() {
        // Configurazioni globali UIKit per aspetto pulito nativo
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
    }
}
