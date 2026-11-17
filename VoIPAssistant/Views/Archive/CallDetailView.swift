import SwiftUI

public struct CallDetailView: View {
    let callId: String
    @ObservedObject var viewModel: ArchiveViewModel
    @StateObject private var playerManager = AudioPlayerManager()
    @State private var selectedTab: Int = 0

    private var currentCall: CallRecord? {
        if let sel = viewModel.selectedCall, sel.id == callId {
            return sel
        }
        return viewModel.calls.first(where: { $0.id == callId })
    }

    public init(callId: String, viewModel: ArchiveViewModel) {
        self.callId = callId
        self.viewModel = viewModel
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if let call = currentCall {
                    // Header Scheda Chiamata
                    VStack(spacing: 12) {
                        HStack(spacing: 14) {
                            Circle()
                                .fill(Color.blue.opacity(0.15))
                                .frame(width: 54, height: 54)
                                .overlay(
                                    Text(call.initials)
                                        .font(.title3.bold())
                                        .foregroundColor(.blue)
                                )

                            VStack(alignment: .leading, spacing: 3) {
                                Text(call.displayName)
                                    .font(.title3.bold())
                                Text(call.recipientNumber)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 4) {
                                Text(call.statusLocalized)
                                    .font(.caption2.bold())
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(call.statusBadgeColor)
                                    .cornerRadius(6)

                                Text(call.formattedDuration)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }

                        HStack {
                            Image(systemName: "calendar")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(call.formattedDate)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                    }
                    .padding(14)
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(14)

                    // Player Audio Registrazione
                    if call.hasAudio {
                        AudioPlayerView(
                            playerManager: playerManager,
                            audioURL: APIService.shared.getAudioURL(callId: call.id)
                        )
                    }

                    // Selettore Sezione (3 Schede)
                    Picker("Sezione", selection: $selectedTab) {
                        Text("Trascrizione").tag(0)
                        Text("Mappa Cmap").tag(1)
                        Text("Eventi (\(call.calendarEvents.count))").tag(2)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.top, 4)

                    // Contenuto della Scheda
                    switch selectedTab {
                    case 0:
                        TranscriptionView(transcription: call.transcription ?? "")
                    case 1:
                        ConceptMapView(conceptMap: call.conceptMap)
                    case 2:
                        CalendarEventsView(events: call.calendarEvents)
                    default:
                        EmptyView()
                    }
                } else {
                    ProgressView("Caricamento dettagli chiamata...")
                        .padding(.vertical, 40)
                }
            }
            .padding(16)
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle(currentCall?.displayName ?? "Dettaglio Chiamata")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if let call = currentCall {
                    Button(action: {
                        Task {
                            await viewModel.reprocess(call: call)
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        }
        .task {
            await viewModel.loadCallDetail(id: callId)
        }
    }
}
