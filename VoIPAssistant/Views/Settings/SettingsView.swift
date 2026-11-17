import SwiftUI

public struct SettingsView: View {
    @ObservedObject private var settings = AppSettings.shared
    @State private var isTestingConnection: Bool = false
    @State private var connectionStatusMessage: String? = nil
    @State private var isConnectionSuccess: Bool = false
    @State private var isTokenVisible: Bool = false
    @State private var showingResetAlert: Bool = false

    public var body: some View {
        NavigationView {
            Form {
                // Sezione VPS Backend
                Section(
                    header: Text("CONFIGURAZIONE SERVER VPS"),
                    footer: Text("L'URL del reverse proxy HTTPS della VPS Ubuntu che inoltra al backend FastAPI (porta 8890).")
                ) {
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

                        if isTokenVisible {
                            TextField("API Secret Token", text: $settings.apiToken)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                        } else {
                            SecureField("API Secret Token", text: $settings.apiToken)
                        }

                        Button(action: { isTokenVisible.toggle() }) {
                            Image(systemName: isTokenVisible ? "eye.slash" : "eye")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(BorderlessButtonStyle())
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
                                    .fontWeight(.medium)
                            }
                        }
                    }
                    .disabled(isTestingConnection)

                    if let msg = connectionStatusMessage {
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: isConnectionSuccess ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                .foregroundColor(isConnectionSuccess ? .green : .red)
                                .padding(.top, 2)
                            Text(msg)
                                .font(.footnote)
                                .foregroundColor(isConnectionSuccess ? .green : .red)
                        }
                        .padding(.vertical, 2)
                    }
                }

                // Sezione Parametri VoIP & Triangolazione
                Section(
                    header: Text("PARAMETRI TRIANGOLAZIONE VOIP"),
                    footer: Text("Il destinatario vedrà sempre e solo il tuo cellulare reale. Il ponte VoIP rimane silenzioso in conferenza.")
                ) {
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

                // Sezione Ripristino
                Section {
                    Button(role: .destructive, action: { showingResetAlert = true }) {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Ripristina Impostazioni Predefinite")
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
                        Text("1.0.1 (Build 2)")
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
                        Text("Compatibile Feather / AltStore / TrollStore")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Impostazioni")
            .alert(isPresented: $showingResetAlert) {
                Alert(
                    title: Text("Ripristinare le impostazioni?"),
                    message: Text("Tutti i parametri torneranno ai valori di fabbrica (gestoreserver.duckdns.org/voip, 07441590208, 3669650010)."),
                    primaryButton: .destructive(Text("Ripristina")) {
                        settings.resetToDefaults()
                        connectionStatusMessage = nil
                    },
                    secondaryButton: .cancel(Text("Annulla"))
                )
            }
        }
    }

    private func testConnection() {
        isTestingConnection = true
        connectionStatusMessage = nil

        Task {
            do {
                let result = try await APIService.shared.checkHealth()
                DispatchQueue.main.async {
                    self.isTestingConnection = false
                    self.isConnectionSuccess = result.success
                    self.connectionStatusMessage = result.message
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
