import SwiftUI
import UserNotifications

@main
struct VoIPAssistantApp: App {
    init() {
        // Configurazioni globali UIKit per aspetto pulito nativo
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance

        // Richiedi permessi notifiche locali per banner promemoria conferenza
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
    }
}
