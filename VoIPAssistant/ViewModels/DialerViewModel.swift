import Foundation
import SwiftUI
import UIKit

@MainActor
public final class DialerViewModel: ObservableObject {
    @Published public var phoneNumber: String = ""
    @Published public var contactName: String = ""
    @Published public var isShowingContactPicker: Bool = false
    @Published public var isCallingInProgress: Bool = false
    @Published public var isInitiatingCall: Bool = false
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
    }

    public func setContact(name: String, number: String) {
        self.contactName = name
        self.phoneNumber = number
    }

    /// Avvia il flusso di triangolazione inversa:
    /// 1. Notifica la VPS (crea sessione con nome/numero)
    /// 2. Copia negli appunti il numero del destinatario
    /// 3. Chiama il numero VoIP ponte 07441590208
    /// 4. Mostra la schermata "Guida Conferenza" per avviare la seconda chiamata
    public func startRecordedCall() {
        let cleanNumber = phoneNumber.replacingOccurrences(of: " ", with: "")
        guard !cleanNumber.isEmpty else {
            errorMessage = "Inserisci o seleziona un numero di telefono."
            return
        }

        errorMessage = nil
        isInitiatingCall = true

        Task {
            do {
                // 1. Notifica la VPS per collegare la registrazione audio al contatto
                let sessionId = try await apiService.initiateCall(
                    recipientNumber: cleanNumber,
                    recipientName: contactName.isEmpty ? "Destinatario" : contactName
                )
                self.activeSessionId = sessionId

                // 2. Copia negli appunti per comodità dell'utente
                UIPasteboard.general.string = cleanNumber

                // 3. Avvia chiamata ponte al PBX Asterisk sulla VPS
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
                            // Mostra guida per unire la chiamata
                            self.isCallingInProgress = true
                        } else {
                            self.errorMessage = "Impossibile avviare la chiamata telefonica."
                        }
                    }
                } else {
                    self.isInitiatingCall = false
                    self.isCallingInProgress = true
                    self.errorMessage = "Questo dispositivo non supporta le chiamate telefoniche (es. Simulatore)."
                }
            } catch {
                self.isInitiatingCall = false
                self.errorMessage = "Errore connessione server: \(error.localizedDescription)"
                // Consentiamo comunque di avviare la chiamata ponte
                self.isCallingInProgress = true
            }
        }
    }

    /// Chiama il numero reale del destinatario.
    /// Il destinatario vedrà ESCLUSIVAMENTE il numero cellulare reale dell'utente (3669650010).
    public func callRecipientNow() {
        let cleanNumber = phoneNumber.replacingOccurrences(of: " ", with: "")
        guard let url = URL(string: "tel://\(cleanNumber)") else { return }
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }

    public func endCallSession() {
        isCallingInProgress = false
        activeSessionId = nil
    }
}
