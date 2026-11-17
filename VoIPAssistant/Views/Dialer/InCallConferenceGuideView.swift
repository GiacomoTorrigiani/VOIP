import SwiftUI

public struct InCallConferenceGuideView: View {
    @ObservedObject var viewModel: DialerViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var hasCopied: Bool = false

    public var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Scheda Destinatario Selezionato
                    VStack(spacing: 12) {
                        HStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(Color.blue.opacity(0.15))
                                    .frame(width: 50, height: 50)
                                Text(initials(for: viewModel.contactName))
                                    .font(.headline.bold())
                                    .foregroundColor(.blue)
                            }

                            VStack(alignment: .leading, spacing: 3) {
                                Text(viewModel.contactName.isEmpty ? "Destinatario Selezionato" : viewModel.contactName)
                                    .font(.title3.bold())
                                    .foregroundColor(.primary)

                                Text(viewModel.phoneNumber)
                                    .font(.subheadline.monospacedDigit())
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Button(action: {
                                UIPasteboard.general.string = viewModel.phoneNumber
                                hasCopied = true
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    hasCopied = false
                                }
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: hasCopied ? "checkmark" : "doc.on.doc")
                                    Text(hasCopied ? "Copiato" : "Copia")
                                }
                                .font(.caption.bold())
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.secondary.opacity(0.15))
                                .cornerRadius(8)
                            }
                        }
                    }
                    .padding(16)
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(16)

                    // PASSO 1: Chiama Numero VoIP
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("PASSO 1")
                                .font(.caption.bold())
                                .foregroundColor(.green)
                            Spacer()
                            if viewModel.hasDialedBridge {
                                Label("Chiamato", systemImage: "checkmark.circle.fill")
                                    .font(.caption.bold())
                                    .foregroundColor(.green)
                            }
                        }

                        Text("Chiama il Registratore VoIP")
                            .font(.headline)

                        Text("Numero VoIP PBX: 07441590208")
                            .font(.subheadline.monospacedDigit().bold())
                            .foregroundColor(.primary)

                        Text("Il centralino risponde e rimane in ascolto silenzioso. Questa chiamata è completamente gratuita (0,00 €/min).")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Button(action: {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            viewModel.callBridgeNow()
                        }) {
                            HStack(spacing: 10) {
                                if viewModel.isInitiatingCall {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Image(systemName: viewModel.hasDialedBridge ? "arrow.clockwise" : "phone.fill")
                                    Text(viewModel.hasDialedBridge ? "Richiama VoIP (07441590208)" : "1. Chiama Numero VoIP (07441590208)")
                                        .font(.headline)
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(viewModel.hasDialedBridge ? Color.gray : Color.green)
                            .cornerRadius(12)
                        }
                        .disabled(viewModel.isInitiatingCall)
                    }
                    .padding(16)
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(viewModel.hasDialedBridge ? Color.clear : Color.green.opacity(0.4), lineWidth: 1.5)
                    )

                    // PASSO 2: Aggiungi Destinatario
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("PASSO 2")
                                .font(.caption.bold())
                                .foregroundColor(.blue)
                            Spacer()
                            if viewModel.hasDialedRecipient {
                                Label("Aggiunto", systemImage: "checkmark.circle.fill")
                                    .font(.caption.bold())
                                    .foregroundColor(.blue)
                            }
                        }

                        Text("Aggiungi Destinatario alla Chiamata")
                            .font(.headline)

                        Text("Tocca questo pulsante per chiamare \(viewModel.contactName.isEmpty ? "il destinatario" : viewModel.contactName). iOS metterà il VoIP in attesa e comporrà il numero con il tuo cellulare reale (3669650010).")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Button(action: {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            viewModel.callRecipientNow()
                        }) {
                            HStack(spacing: 10) {
                                Image(systemName: "person.crop.circle.badge.plus")
                                Text("2. Aggiungi \(viewModel.contactName.isEmpty ? "Destinatario" : viewModel.contactName) alla Chiamata")
                                    .font(.headline)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(viewModel.hasDialedBridge ? Color.blue : Color.blue.opacity(0.7))
                            .cornerRadius(12)
                            .shadow(color: viewModel.hasDialedBridge ? Color.blue.opacity(0.4) : Color.clear, radius: 8, y: 3)
                        }
                    }
                    .padding(16)
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(viewModel.hasDialedBridge ? Color.blue.opacity(0.6) : Color.clear, lineWidth: 2)
                    )

                    // PASSO 3: Premi Unisci
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 8) {
                            Text("PASSO 3")
                                .font(.caption.bold())
                                .foregroundColor(.orange)
                            Spacer()
                        }

                        Text("Premi 'Unisci' (Merge) sullo Schermo iPhone")
                            .font(.headline)

                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "arrow.triangle.merge")
                                .font(.system(size: 28))
                                .foregroundColor(.orange)
                                .padding(.top, 2)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Sul display della telefonata di iOS apparirà il tasto 'Unisci'.")
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                                Text("Premilo subito: le due chiamate confluiranno in conferenza. Tu parlerai normalmente con \(viewModel.contactName.isEmpty ? "il destinatario" : viewModel.contactName) e il registratore registrerà tutto in silenzio!")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(16)
                    .background(Color.orange.opacity(0.08))
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                    )

                    // Suggerimento Notifica Banner
                    HStack(spacing: 10) {
                        Image(systemName: "bell.badge.fill")
                            .foregroundColor(.blue)
                        Text("Mentre sei in chiamata, ti arriverà anche una notifica in alto sullo schermo per tornare subito a questa guida.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.secondary.opacity(0.08))
                    .cornerRadius(12)

                    Spacer().frame(height: 20)
                }
                .padding()
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Conferenza Registrata")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Chiudi") {
                        viewModel.endCallSession()
                        dismiss()
                    }
                }
            }
        }
    }

    private func initials(for name: String) -> String {
        let parts = name.split(separator: " ")
        if let first = parts.first?.first {
            if parts.count > 1, let second = parts.last?.first {
                return "\(first)\(second)".uppercased()
            }
            return String(first).uppercased()
        }
        return "📞"
    }
}
