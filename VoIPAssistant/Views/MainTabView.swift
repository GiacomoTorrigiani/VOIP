import SwiftUI

public struct MainTabView: View {
    @State private var selectedTab: Int = 0

    public var body: some View {
        TabView(selection: $selectedTab) {
            DialerView()
                .tabItem {
                    Label("Dialer", systemImage: "phone.fill")
                }
                .tag(0)

            ArchiveView()
                .tabItem {
                    Label("Archivio & Mappe", systemImage: "folder.fill")
                }
                .tag(1)

            SettingsView()
                .tabItem {
                    Label("Impostazioni", systemImage: "gearshape.fill")
                }
                .tag(2)
        }
    }
}
