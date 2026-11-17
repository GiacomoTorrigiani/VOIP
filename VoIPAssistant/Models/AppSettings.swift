import Foundation
import SwiftUI

/// Gestione centralizzata delle impostazioni dell'app salvate in UserDefaults (@AppStorage)
public final class AppSettings: ObservableObject {
    public static let shared = AppSettings()

    @AppStorage("server_url") public var serverURL: String = "https://gestoreserver.duckdns.org/voip"
    @AppStorage("api_token") public var apiToken: String = "TorriflixVoip2026SecureKey!"
    @AppStorage("bridge_number") public var bridgeNumber: String = "07441590208"
    @AppStorage("caller_number") public var callerNumber: String = "3669650010"

    private init() {}

    /// Pulisce l'URL del server rimuovendo slash finali
    public var cleanServerURL: String {
        var url = serverURL.trimmingCharacters(in: .whitespacesAndNewlines)
        while url.hasSuffix("/") {
            url.removeLast()
        }
        return url
    }
}
