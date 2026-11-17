import SwiftUI

public struct SettingsView: View {
    @ObservedObject private var settings = AppSettings.shared
    @State private var isTestingConnection: Bool = false
    @State private var connectionStatusMessage: String? = nil
    @State private var isConnectionSuccess: Bool = false

    public var body: some View {
        NavigationView {
            Form {
                // Sezione VPS Backend
                Section(header: Text("CONFIGURAZIONE SERVER VPS"), footer: Text("L'URL della VPS Ubuntu su cui è attivo il backend FastAPI (porta default: 8000).")) {
                    HStack {
                        Image(systemName: "server.rack")
                            .foregroundColor(.blue)
                            .frame(width: 24)
                        TextField("https://gestoreserver.duckdns.org/voip", text: $settings.serverURL)
                            .keyboardType(.URL)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }

                    HStack {
                        Image(systemName: "key.fill")
                            .foregroundColor(.orange)
                            .frame(width: 24)
                        SecureField("API Secret Token", text: $settings.apiToken)
                    }

                    Button(action: testConnection) {
                        HStack {
                            if isTestingConnection {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                Text("Verifica in corso...")
                                    .foregroundColor(.secondary)
                            } else {
                                Image(systemName: "antenna.radiowaves.left.and.right")
                                    .foregroundColor(.blue)
                                Text("Verifica Connessione VPS")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .disabled(isTestingConnection)

                    if let msg = connectionStatusMessage {
                        HStack(spacing: 8) {
                            Image(systemName: isConnectionSuccess ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                .foregroundColor(isConnectionSuccess ? .green : .red)
                            Text(msg)
                                .font(.caption)
                                .foregroundColor(isConnectionSuccess ? .green : .red)
                        }
                    }
                }

                // Sezione Parametri VoIP & Triangolazione
                Section(header: Text("PARAMETRI TRIANGOLAZIONE VOIP"), footer: Text("Il destinatario vedrà sempre e solo il tuo cellulare reale. Il ponte VoIP rimane silenzioso in conferenza.")) {
                    HStack {
                        Image(systemName: "phone.arrow.up.right")
                            .foregroundColor(.green)
                            .frame(width: 24)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Numero Ponte VoIP (PBX)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TextField("07441590208", text: $settings.bridgeNumber)
                                .keyboardType(.phonePad)
                        }
                    }

                    HStack {
                        Image(systemName: "iphone")
                            .foregroundColor(.purple)
                            .frame(width: 24)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Tuo Cellulare Reale (Caller ID)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TextField("3669650010", text: $settings.callerNumber)
                                .keyboardType(.phonePad)
                        }
                    }
                }

                // Sezione Architettura & Sicurezza
                Section(header: Text("COME FUNZIONA LA TRIANGOLAZIONE")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("1. Chiamata Ponte Inversa")
                            .font(.subheadline.bold())
                        Text("L'app notifica la VPS e avvia la chiamata verso il ponte 07441590208.")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Divider()

                        Text("2. Chiamata Diretta Destinatario")
                            .font(.subheadline.bold())
                        Text("L'app guida l'avvio della seconda chiamata: il destinatario vede solo il tuo numero reale (3669650010).")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Divider()

                        Text("3. Registrazione & AI Gemini")
                            .font(.subheadline.bold())
                        Text("Premendo 'Unisci' su iOS, Asterisk registra l'audio completo e Gemini 2.5 Flash genera trascrizione, mappa Cmap e appuntamenti Google Calendar.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }

                // Info App
                Section(header: Text("INFORMAZIONI")) {
                    HStack {
                        Text("Versione")
                        Spacer()
                        Text("1.0.0 (Build 1)")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Modello AI")
                        Spacer()
                        Text("Gemini 2.5 Flash")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Sideloading")
                        Spacer()
                        Text("Compatibile AltStore / TrollStore")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Impostazioni")
        }
    }

    private func testConnection() {
        isTestingConnection = true
        connectionStatusMessage = nil

        Task {
            do {
                let success = try await APIService.shared.checkHealth()
                DispatchQueue.main.async {
                    self.isTestingConnection = false
                    self.isConnectionSuccess = success
                    self.connectionStatusMessage = success ? "Connessione riuscita! Il backend VPS risponde correttamente." : "Il backend ha risposto con uno stato anomalo."
                }
            } catch {
                DispatchQueue.main.async {
                    self.isTestingConnection = false
                    self.isConnectionSuccess = false
                    self.connectionStatusMessage = "Errore di connessione: \(error.localizedDescription)"
                }
            }
        }
    }
}
