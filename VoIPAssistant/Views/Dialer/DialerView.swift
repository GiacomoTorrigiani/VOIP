import SwiftUI

public struct DialerView: View {
    @StateObject private var viewModel = DialerViewModel()
    @State private var showingContactPicker = false

    public var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                // Barra Rubrica Contatti
                Button(action: {
                    showingContactPicker = true
                }) {
                    HStack {
                        Image(systemName: "person.crop.circle.badge.plus")
                            .font(.system(size: 20))
                            .foregroundColor(.blue)

                        if !viewModel.contactName.isEmpty {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(viewModel.contactName)
                                    .font(.subheadline.bold())
                                    .foregroundColor(.primary)
                                Text("Tocca per cambiare contatto")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        } else {
                            Text("Seleziona dalla rubrica...")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(12)
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)

                // Visualizzazione Numero Digitato
                VStack(spacing: 4) {
                    if !viewModel.contactName.isEmpty {
                        Text(viewModel.contactName)
                            .font(.headline)
                            .foregroundColor(.blue)
                    }

                    HStack(spacing: 8) {
                        Spacer()
                        Text(viewModel.phoneNumber.isEmpty ? "Inserisci numero" : viewModel.phoneNumber)
                            .font(.system(size: 34, weight: .medium, design: .rounded))
                            .foregroundColor(viewModel.phoneNumber.isEmpty ? .secondary.opacity(0.4) : .primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)

                        if !viewModel.phoneNumber.isEmpty {
                            Button(action: {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                viewModel.deleteLastDigit()
                            }) {
                                Image(systemName: "delete.left.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.secondary)
                            }
                            .padding(.leading, 8)
                        }
                        Spacer()
                    }
                    .frame(height: 48)
                }
                .padding(.horizontal, 20)

                if let err = viewModel.errorMessage {
                    Text(err)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal, 20)
                }

                Spacer()

                // Tastierino Numerico
                KeypadView { digit in
                    viewModel.appendDigit(digit)
                }

                Spacer()

                // Pulsante Verde di Chiamata Registrata
                HStack(spacing: 30) {
                    Spacer()

                    Button(action: {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        viewModel.startRecordedCall()
                    }) {
                        HStack(spacing: 10) {
                            if viewModel.isInitiatingCall {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "phone.fill")
                                    .font(.title2)
                                Text("Avvia Chiamata Registrata")
                                    .font(.headline)
                            }
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 16)
                        .background(viewModel.phoneNumber.isEmpty ? Color.gray.opacity(0.4) : Color.green)
                        .clipShape(Capsule())
                        .shadow(color: viewModel.phoneNumber.isEmpty ? .clear : Color.green.opacity(0.4), radius: 8, y: 4)
                    }
                    .disabled(viewModel.phoneNumber.isEmpty || viewModel.isInitiatingCall)

                    Spacer()
                }
                .padding(.bottom, 24)
            }
            .navigationTitle("Dialer VoIP")
            .sheet(isPresented: $showingContactPicker) {
                ContactPickerView { name, number in
                    viewModel.setContact(name: name, number: number)
                }
            }
            .sheet(isPresented: $viewModel.isCallingInProgress) {
                InCallConferenceGuideView(viewModel: viewModel)
            }
        }
    }
}
