import SwiftUI

public struct CalendarEventsView: View {
    let events: [CalendarEvent]
    @State private var copiedEventId: String? = nil

    public init(events: [CalendarEvent]) {
        self.events = events
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("APPUNTAMENTI E IMPEGNI RILEVATI")
                .font(.caption.bold())
                .foregroundColor(.secondary)

            if events.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    Text("Nessun appuntamento o data rilevata in questa conversazione.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                ForEach(events) { event in
                    CalendarEventCard(
                        event: event,
                        isCopied: copiedEventId == event.id,
                        onCopy: {
                            let text = "\(event.title)\nData: \(event.formattedStartDate)\n\(event.notes ?? "")"
                            UIPasteboard.general.string = text
                            copiedEventId = event.id
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                copiedEventId = nil
                            }
                        }
                    )
                }
            }
        }
    }
}

private struct CalendarEventCard: View {
    let event: CalendarEvent
    let isCopied: Bool
    let onCopy: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(event.title)
                        .font(.headline)
                        .foregroundColor(.primary)

                    HStack(spacing: 6) {
                        Image(systemName: "clock")
                            .font(.caption)
                            .foregroundColor(.blue)
                        Text(event.formattedStartDate)
                            .font(.subheadline.bold())
                            .foregroundColor(.blue)
                    }
                }

                Spacer()

                Button(action: onCopy) {
                    Image(systemName: isCopied ? "checkmark.circle.fill" : "doc.on.doc")
                        .foregroundColor(isCopied ? .green : .secondary)
                        .font(.subheadline)
                }
            }

            if let notes = event.notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
            }

            if let loc = event.location, !loc.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.caption)
                        .foregroundColor(.red)
                    Text(loc)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Divider()

            // Pulsante Aggiungi a Google Calendar
            if let gcalURL = event.googleCalendarURL {
                Button(action: {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    UIApplication.shared.open(gcalURL, options: [:], completionHandler: nil)
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "calendar.badge.plus")
                            .font(.subheadline.bold())
                        Text("Aggiungi a Google Calendar")
                            .font(.subheadline.bold())
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .cornerRadius(10)
                }
            }
        }
        .padding(14)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.blue.opacity(0.15), lineWidth: 1)
        )
    }
}
