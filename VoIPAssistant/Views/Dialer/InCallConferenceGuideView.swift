import SwiftUI

public struct InCallConferenceGuideView: View {
    @ObservedObject var viewModel: DialerViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var hasCopied: Bool = false

    public var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header Status
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(Color.green.opacity(0.15))
                                .frame(width: 80, height: 80)
                            Image(systemName: "phone.badge.waveform.fill")
                                .font(.system(size: 38))
                                .foregroundColor(.green)
                        }

                        Text("Chiamata Ponte Attiva")
                            .font(.title2.bold())

                        Text("VoIP Ponte: 07441590208")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 10)

                    // Scheda Destinatario
                    VStack(spacing: 8) {
                        Text("DESTINATARIO")
                            .font(.caption.bold())
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(viewModel.contactName.isEmpty ? "Numero Selezionato" : viewModel.contactName)
                                    .font(.headline)
                                Text(viewModel.phoneNumber)
                                    .font(.title3.monospacedDigit())
                                    .foregroundColor(.primary)
                            }
                            Spacer()

                            Button(action: {
                                UIPasteboard.general.string = viewModel.phoneNumber
                                hasCopied = true
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
                    .padding()
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(14)

                    // Pulsante Azione Rapida: Chiama Destinatario
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        viewModel.callRecipientNow()
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "phone.arrow.up.right.fill")
                                .font(.title3)
                            Text("Chiama Destinatario Ora")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.green)
                        .cornerRadius(14)
                        .shadow(color: Color.green.opacity(0.3), radius: 8, y: 4)
                    }

                    // Guida Passaggio per Passaggio
                    VStack(alignment: .leading, spacing: 14) {
                        Text("COME COMPLETARE LA REGISTRAZIONE")
                            .font(.caption.bold())
                            .foregroundColor(.secondary)

                        StepRow(
                            step: "1",
                            title: "Chiamata Ponte Avviata",
                            description: "Il PBX Asterisk ha risposto sul numero 07441590208 ed è in ascolto silenzioso con MixMonitor attivo."
                        )

                        StepRow(
                            step: "2",
                            title: "Chiama il Destinatario",
                            description: "Premi il pulsante verde sopra. La chiamata al ponte verrà messa automaticamente in attesa da iOS."
                        )

                        StepRow(
                            step: "3",
                            title: "Premi 'Unisci' (Merge)",
                            description: "Sulla schermata telefonica di iOS apparirà il tasto 'Unisci'. Premilo subito per far confluire il destinatario e la linea ponte nella conferenza!"
                        )
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(14)

                    // Avviso Privacy & Caller ID
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "shield.checkmark.fill")
                            .foregroundColor(.blue)
                            .font(.title3)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Triangolazione Inversa Attiva")
                                .font(.subheadline.bold())
                            Text("Il destinatario vedrà ESCLUSIVAMENTE il tuo numero reale (3669650010). Il numero VoIP 07441590208 rimarrà completamente invisibile.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color.blue.opacity(0.08))
                    .cornerRadius(12)

                    Spacer().frame(height: 10)
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
}

private struct StepRow: View {
    let step: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(step)
                .font(.headline)
                .foregroundColor(.white)
                .frame(width: 28, height: 28)
                .background(Color.blue)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.bold())
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
