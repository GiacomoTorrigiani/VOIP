import Foundation
import SwiftUI
import UIKit
import UserNotifications

@MainActor
public final class DialerViewModel: ObservableObject {
    @Published public var phoneNumber: String = ""
    @Published public var contactName: String = ""
    @Published public var isShowingContactPicker: Bool = false
    @Published public var isCallingInProgress: Bool = false
    @Published public var isInitiatingCall: Bool = false
    @Published public var hasDialedBridge: Bool = false
    @Published public var hasDialedRecipient: Bool = false
    @Published public var activeSessionId: String? = nil
    @Published public var errorMessage: String? = nil

    private let settings = AppSettings.shared
    private let apiService = APIService.shared

    public init() {}

    public func appendDigit(_ digit: String) {
        if phoneNumber.count < 18 {
            phoneNumber.append(digit)
        }
    }

    public func deleteLastDigit() {
        if !phoneNumber.isEmpty {
            phoneNumber.removeLast()
        }
        if phoneNumber.isEmpty {
            contactName = ""
        }
    }

    public func clear() {
        phoneNumber = ""
        contactName = ""
        errorMessage = nil
        hasDialedBridge = false
        hasDialedRecipient = false
    }

    /// Quando l'utente seleziona un contatto dalla rubrica
    public func setContact(name: String, number: String) {
        self.contactName = name
        self.phoneNumber = number
        self.hasDialedBridge = false
        self.hasDialedRecipient = false
        // Mostra immediatamente la schermata con il numero VoIP e i passaggi guidati
        self.isCallingInProgress = true
    }

    /// Apre la schermata guidata per il numero digitato sul tastierino
    public func openConferenceGuide() {
        let cleanNumber = phoneNumber.replacingOccurrences(of: " ", with: "")
        guard !cleanNumber.isEmpty else {
            errorMessage = "Inserisci o seleziona un numero di telefono."
            return
        }
        self.errorMessage = nil
        self.isCallingInProgress = true
    }

    /// Passo 1: Chiama il numero ponte VoIP registratore (07441590208)
    public func callBridgeNow() {
        let cleanRecipient = phoneNumber.replacingOccurrences(of: " ", with: "")
        guard !cleanRecipient.isEmpty else {
            errorMessage = "Inserisci o seleziona un numero di telefono."
            return
        }

        errorMessage = nil
        isInitiatingCall = true

        Task {
            do {
                // Notifica il backend VPS prima di comporre
                let sessionId = try await apiService.initiateCall(
                    recipientNumber: cleanRecipient,
                    recipientName: contactName.isEmpty ? "Destinatario" : contactName
                )
                self.activeSessionId = sessionId

                // Copia negli appunti per sicurezza
                UIPasteboard.general.string = cleanRecipient

                // Schedula promemoria banner dopo 3 secondi
                scheduleReminderNotification(
                    name: contactName.isEmpty ? cleanRecipient : contactName,
                    number: cleanRecipient
                )

                let bridge = settings.bridgeNumber.replacingOccurrences(of: " ", with: "")
                guard let bridgeURL = URL(string: "tel://\(bridge)") else {
                    self.errorMessage = "Numero ponte non valido."
                    self.isInitiatingCall = false
                    return
                }

                if UIApplication.shared.canOpenURL(bridgeURL) {
                    UIApplication.shared.open(bridgeURL, options: [:]) { success in
                        self.isInitiatingCall = false
                        if success {
                            self.hasDialedBridge = true
                        } else {
                            self.errorMessage = "Impossibile avviare la chiamata verso il VoIP."
                        }
                    }
                } else {
                    self.isInitiatingCall = false
                    self.hasDialedBridge = true
                    self.errorMessage = "Questo dispositivo non supporta chiamate telefoniche (Simulatore)."
                }
            } catch {
                self.isInitiatingCall = false
                self.hasDialedBridge = true
                self.errorMessage = "Avviso: Impossibile contattare server, avvio comunque il ponte VoIP..."
                let bridge = settings.bridgeNumber.replacingOccurrences(of: " ", with: "")
                if let bridgeURL = URL(string: "tel://\(bridge)"), UIApplication.shared.canOpenURL(bridgeURL) {
                    UIApplication.shared.open(bridgeURL, options: [:], completionHandler: nil)
                }
            }
        }
    }

    /// Passo 2: Aggiungi il destinatario alla chiamata
    public func callRecipientNow() {
        let cleanNumber = phoneNumber.replacingOccurrences(of: " ", with: "")
        guard let url = URL(string: "tel://\(cleanNumber)") else { return }
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:]) { success in
                if success {
                    self.hasDialedRecipient = true
                }
            }
        }
    }

    private func scheduleReminderNotification(name: String, number: String) {
        let content = UNMutableNotificationContent()
        content.title = "📞 Aggiungi \(name) alla Chiamata"
        content.body = "Tocca qui per chiamare il destinatario e poi premi 'Unisci' sul display!"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3.0, repeats: false)
        let request = UNNotificationRequest(
            identifier: "conf_step2_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }

    public func endCallSession() {
        isCallingInProgress = false
        hasDialedBridge = false
        hasDialedRecipient = false
        activeSessionId = nil
    }
}
