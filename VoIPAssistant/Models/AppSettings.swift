import Foundation
import SwiftUI

/// Gestione centralizzata delle impostazioni dell'app salvate in UserDefaults
public final class AppSettings: ObservableObject {
    public static let shared = AppSettings()

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let serverURL = "server_url"
        static let apiToken = "api_token"
        static let bridgeNumber = "bridge_number"
        static let callerNumber = "caller_number"
    }

    public static let defaultServerURL = "https://gestoreserver.duckdns.org/voip"
    public static let defaultApiToken = "TorriflixVoip2026SecureKey!"
    public static let defaultBridgeNumber = "07441590208"
    public static let defaultCallerNumber = "3669650010"

    @Published public var serverURL: String {
        didSet { defaults.set(serverURL, forKey: Keys.serverURL) }
    }

    @Published public var apiToken: String {
        didSet { defaults.set(apiToken, forKey: Keys.apiToken) }
    }

    @Published public var bridgeNumber: String {
        didSet { defaults.set(bridgeNumber, forKey: Keys.bridgeNumber) }
    }

    @Published public var callerNumber: String {
        didSet { defaults.set(callerNumber, forKey: Keys.callerNumber) }
    }

    private init() {
        let savedURL = defaults.string(forKey: Keys.serverURL)
        self.serverURL = (savedURL != nil && !savedURL!.trimmingCharacters(in: .whitespaces).isEmpty)
            ? savedURL!
            : Self.defaultServerURL

        let savedToken = defaults.string(forKey: Keys.apiToken)
        self.apiToken = (savedToken != nil && !savedToken!.trimmingCharacters(in: .whitespaces).isEmpty)
            ? savedToken!
            : Self.defaultApiToken

        let savedBridge = defaults.string(forKey: Keys.bridgeNumber)
        self.bridgeNumber = (savedBridge != nil && !savedBridge!.trimmingCharacters(in: .whitespaces).isEmpty)
            ? savedBridge!
            : Self.defaultBridgeNumber

        let savedCaller = defaults.string(forKey: Keys.callerNumber)
        self.callerNumber = (savedCaller != nil && !savedCaller!.trimmingCharacters(in: .whitespaces).isEmpty)
            ? savedCaller!
            : Self.defaultCallerNumber
    }

    /// Reimposta tutte le impostazioni ai valori predefiniti
    public func resetToDefaults() {
        self.serverURL = Self.defaultServerURL
        self.apiToken = Self.defaultApiToken
        self.bridgeNumber = Self.defaultBridgeNumber
        self.callerNumber = Self.defaultCallerNumber
    }

    /// Pulisce l'URL del server rimuovendo slash finali
    public var cleanServerURL: String {
        var url = serverURL.trimmingCharacters(in: .whitespacesAndNewlines)
        while url.hasSuffix("/") {
            url.removeLast()
        }
        return url
    }
}
