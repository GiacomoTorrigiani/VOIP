import SwiftUI

public struct ArchiveView: View {
    @StateObject private var viewModel = ArchiveViewModel()

    public var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Barra di Ricerca
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Cerca per nome, numero o testo...", text: $viewModel.searchQuery)
                        .font(.subheadline)
                    if !viewModel.searchQuery.isEmpty {
                        Button(action: { viewModel.searchQuery = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(10)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)

                if viewModel.isLoading && viewModel.calls.isEmpty {
                    Spacer()
                    ProgressView("Caricamento archivio chiamate...")
                    Spacer()
                } else if viewModel.filteredCalls.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "waveform.badge.magnifyingglass")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text(viewModel.searchQuery.isEmpty ? "Nessuna chiamata registrata" : "Nessun risultato trovato")
                            .font(.headline)
                            .foregroundColor(.primary)
                        Text(viewModel.searchQuery.isEmpty ? "Le chiamate registrate e analizzate da Gemini appariranno qui." : "Prova con un altro termine di ricerca.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    Spacer()
                } else {
                    List {
                        ForEach(viewModel.filteredCalls) { call in
                            NavigationLink(destination: CallDetailView(callId: call.id, viewModel: viewModel)) {
                                CallRowView(call: call)
                            }
                            .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
                        }
                    }
                    .listStyle(PlainListStyle())
                    .refreshable {
                        await viewModel.refresh()
                    }
                }
            }
            .navigationTitle("Archivio Chiamate")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        Task { await viewModel.refresh() }
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .task {
                await viewModel.loadCalls()
            }
        }
    }
}

private struct CallRowView: View {
    let call: CallRecord

    var body: some View {
        HStack(spacing: 14) {
            Circle()
                .fill(Color.blue.opacity(0.15))
                .frame(width: 46, height: 46)
                .overlay(
                    Text(call.initials)
                        .font(.subheadline.bold())
                        .foregroundColor(.blue)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(call.displayName)
                    .font(.headline)
                    .foregroundColor(.primary)

                Text(call.displaySubtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack(spacing: 6) {
                    if call.transcription != nil {
                        Image(systemName: "text.bubble")
                            .font(.caption2)
                            .foregroundColor(.purple)
                    }
                    if call.conceptMap != nil {
                        Image(systemName: "point.3.connected.trianglepath.dotted")
                            .font(.caption2)
                            .foregroundColor(.blue)
                    }
                    if !call.calendarEvents.isEmpty {
                        Image(systemName: "calendar")
                            .font(.caption2)
                            .foregroundColor(.orange)
                        Text("\(call.calendarEvents.count)")
                            .font(.caption2.bold())
                            .foregroundColor(.orange)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(call.formattedDate)
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Text(call.formattedDuration)
                    .font(.caption.monospacedDigit())
                    .foregroundColor(.primary)

                Text(call.statusLocalized)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(call.statusBadgeColor)
            }
        }
        .padding(.vertical, 4)
    }
}
