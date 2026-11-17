import Foundation

public struct CalendarEvent: Identifiable, Codable, Equatable, Hashable {
    public var id: String
    public var title: String
    public var startISO: String
    public var endISO: String?
    public var notes: String?
    public var location: String?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case startISO = "start_iso"
        case endISO = "end_iso"
        case notes
        case location
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = (try? container.decode(String.self, forKey: .id)) ?? UUID().uuidString
        self.title = (try? container.decode(String.self, forKey: .title)) ?? "Impegno Chiamata"
        self.startISO = (try? container.decode(String.self, forKey: .startISO)) ?? ""
        self.endISO = try? container.decodeIfPresent(String.self, forKey: .endISO)
        self.notes = try? container.decodeIfPresent(String.self, forKey: .notes)
        self.location = try? container.decodeIfPresent(String.self, forKey: .location)
    }

    public init(id: String = UUID().uuidString, title: String, startISO: String, endISO: String? = nil, notes: String? = nil, location: String? = nil) {
        self.id = id
        self.title = title
        self.startISO = startISO
        self.endISO = endISO
        self.notes = notes
        self.location = location
    }

    /// Data formattata leggibile per l'interfaccia utente (es. "20 Nov 2026, 10:30")
    public var formattedStartDate: String {
        guard let date = ISO8601DateFormatter().date(from: startISO) ?? parseCustomISO(startISO) else {
            return startISO
        }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "it_IT")
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    /// URL precompilato per Google Calendar
    public var googleCalendarURL: URL? {
        guard var components = URLComponents(string: "https://calendar.google.com/calendar/render") else {
            return nil
        }

        let startFormatted = formatForGoogleCalendar(startISO)
        let endFormatted: String
        if let end = endISO, !end.isEmpty {
            endFormatted = formatForGoogleCalendar(end)
        } else if let startDate = parseDate(startISO) {
            // Default durata 1 ora
            let endDate = startDate.addingTimeInterval(3600)
            let gCalFormatter = DateFormatter()
            gCalFormatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
            gCalFormatter.timeZone = TimeZone(secondsFromGMT: 0)
            endFormatted = gCalFormatter.string(from: endDate)
        } else {
            endFormatted = startFormatted
        }

        let datesParam = "\(startFormatted)/\(endFormatted)"

        var queryItems = [
            URLQueryItem(name: "action", value: "TEMPLATE"),
            URLQueryItem(name: "text", value: title),
            URLQueryItem(name: "dates", value: datesParam)
        ]

        if let notes = notes, !notes.isEmpty {
            queryItems.append(URLQueryItem(name: "details", value: notes))
        }
        if let location = location, !location.isEmpty {
            queryItems.append(URLQueryItem(name: "location", value: location))
        }

        components.queryItems = queryItems
        return components.url
    }

    private func parseDate(_ isoString: String) -> Date? {
        if let d = ISO8601DateFormatter().date(from: isoString) {
            return d
        }
        return parseCustomISO(isoString)
    }

    private func parseCustomISO(_ isoString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        let formats = [
            "yyyy-MM-dd'T'HH:mm:ssZ",
            "yyyy-MM-dd'T'HH:mm:ss",
            "yyyy-MM-dd HH:mm:ss",
            "yyyy-MM-dd"
        ]
        for f in formats {
            formatter.dateFormat = f
            if let date = formatter.date(from: isoString) {
                return date
            }
        }
        return nil
    }

    private func formatForGoogleCalendar(_ isoString: String) -> String {
        guard let date = parseDate(isoString) else {
            return isoString.replacingOccurrences(of: "-", with: "").replacingOccurrences(of: ":", with: "")
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter.string(from: date)
    }
}
