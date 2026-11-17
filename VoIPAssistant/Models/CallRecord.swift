import Foundation
import SwiftUI

public struct CallRecord: Identifiable, Codable, Equatable {
    public var id: String
    public var sessionId: String?
    public var callerNumber: String
    public var recipientNumber: String
    public var recipientName: String?
    public var timestamp: String
    public var durationSeconds: Int
    public var status: String
    public var hasAudio: Bool
    public var transcription: String?
    public var conceptMap: ConceptMap?
    public var calendarEvents: [CalendarEvent]
    public var summary: String?

    enum CodingKeys: String, CodingKey {
        case id
        case sessionId = "session_id"
        case callerNumber = "caller_number"
        case recipientNumber = "recipient_number"
        case recipientName = "recipient_name"
        case timestamp
        case durationSeconds = "duration_seconds"
        case status
        case hasAudio = "has_audio"
        case transcription
        case conceptMap = "concept_map"
        case calendarEvents = "calendar_events"
        case summary
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.sessionId = try? container.decodeIfPresent(String.self, forKey: .sessionId)
        self.callerNumber = (try? container.decode(String.self, forKey: .callerNumber)) ?? ""
        self.recipientNumber = (try? container.decode(String.self, forKey: .recipientNumber)) ?? ""
        self.recipientName = try? container.decodeIfPresent(String.self, forKey: .recipientName)
        self.timestamp = (try? container.decode(String.self, forKey: .timestamp)) ?? ""
        self.durationSeconds = (try? container.decode(Int.self, forKey: .durationSeconds)) ?? 0
        self.status = (try? container.decode(String.self, forKey: .status)) ?? "unknown"
        self.hasAudio = (try? container.decode(Bool.self, forKey: .hasAudio)) ?? true
        self.transcription = try? container.decodeIfPresent(String.self, forKey: .transcription)
        self.conceptMap = try? container.decodeIfPresent(ConceptMap.self, forKey: .conceptMap)
        self.calendarEvents = (try? container.decode([CalendarEvent].self, forKey: .calendarEvents)) ?? []
        self.summary = try? container.decodeIfPresent(String.self, forKey: .summary)
    }

    public var displayName: String {
        if let name = recipientName, !name.trimmingCharacters(in: .whitespaces).isEmpty {
            return name
        }
        return recipientNumber.isEmpty ? "Numero Sconosciuto" : recipientNumber
    }

    public var displaySubtitle: String {
        if let name = recipientName, !name.trimmingCharacters(in: .whitespaces).isEmpty {
            return recipientNumber
        }
        return "Chiamata registrata"
    }

    public var initials: String {
        let name = displayName
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            let first = parts[0].prefix(1)
            let second = parts[1].prefix(1)
            return "\(first)\(second)".uppercased()
        } else if let first = parts.first?.prefix(2) {
            return String(first).uppercased()
        }
        return "📞"
    }

    public var formattedDuration: String {
        let minutes = durationSeconds / 60
        let seconds = durationSeconds % 60
        if minutes > 0 {
            return String(format: "%d min %02d s", minutes, seconds)
        } else {
            return "\(seconds) s"
        }
    }

    public var formattedDate: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        var parsedDate = formatter.date(from: timestamp)
        if parsedDate == nil {
            let simpleFormatter = ISO8601DateFormatter()
            parsedDate = simpleFormatter.date(from: timestamp)
        }
        if parsedDate == nil {
            let customFormatter = DateFormatter()
            customFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            parsedDate = customFormatter.date(from: timestamp)
        }

        guard let date = parsedDate else { return timestamp }

        let displayFormatter = DateFormatter()
        displayFormatter.locale = Locale(identifier: "it_IT")
        displayFormatter.dateStyle = .medium
        displayFormatter.timeStyle = .short
        return displayFormatter.string(from: date)
    }

    public var statusBadgeColor: Color {
        switch status.lowercased() {
        case "completed":
            return .green
        case "processing":
            return .orange
        case "recording":
            return .red
        case "initiated":
            return .blue
        case "error":
            return .red
        default:
            return .gray
        }
    }

    public var statusLocalized: String {
        switch status.lowercased() {
        case "completed":
            return "Elaborata"
        case "processing":
            return "In Elaborazione AI"
        case "recording":
            return "In Registrazione"
        case "initiated":
            return "In Attesa"
        case "error":
            return "Errore"
        default:
            return status.capitalized
        }
    }
}
