import Foundation

public enum APIError: LocalizedError {
    case invalidURL
    case serverError(statusCode: Int, message: String)
    case decodingError(Error)
    case networkError(Error)
    case unknown

    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Indirizzo URL del server non valido."
        case .serverError(let code, let msg):
            return "Errore server (\(code)): \(msg)"
        case .decodingError(let err):
            return "Errore interpretazione dati: \(err.localizedDescription)"
        case .networkError(let err):
            return "Errore di connessione: \(err.localizedDescription)"
        case .unknown:
            return "Si è verificato un errore sconosciuto."
        }
    }
}

public final class APIService {
    public static let shared = APIService()
    private let settings = AppSettings.shared

    private init() {}

    private func makeRequest(endpoint: String, method: String = "GET", body: Data? = nil) throws -> URLRequest {
        guard let url = URL(string: "\(settings.cleanServerURL)\(endpoint)") else {
            throw APIError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = 15.0
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(settings.apiToken)", forHTTPHeaderField: "Authorization")
        if let body = body {
            request.httpBody = body
        }
        return request
    }

    /// Notifica il server prima di avviare la chiamata per registrare la sessione imminente
    public func initiateCall(recipientNumber: String, recipientName: String) async throws -> String {
        let payload: [String: Any] = [
            "recipient_number": recipientNumber,
            "recipient_name": recipientName,
            "caller_number": settings.callerNumber
        ]
        let data = try JSONSerialization.data(withJSONObject: payload)
        let request = try makeRequest(endpoint: "/api/calls/initiate", method: "POST", body: data)

        let (respData, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw APIError.unknown
        }
        guard (200...299).contains(http.statusCode) else {
            let msg = String(data: respData, encoding: .utf8) ?? "Errore HTTP"
            throw APIError.serverError(statusCode: http.statusCode, message: msg)
        }

        if let json = try? JSONSerialization.jsonObject(with: respData) as? [String: Any],
           let callId = json["call_id"] as? String ?? json["session_id"] as? String {
            return callId
        }
        return UUID().uuidString
    }

    /// Scarica l'elenco delle chiamate registrate ed elaborate
    public func fetchCalls() async throws -> [CallRecord] {
        let request = try makeRequest(endpoint: "/api/calls")
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw APIError.unknown
        }
        guard (200...299).contains(http.statusCode) else {
            let msg = String(data: data, encoding: .utf8) ?? "Errore HTTP"
            throw APIError.serverError(statusCode: http.statusCode, message: msg)
        }

        do {
            let decoder = JSONDecoder()
            return try decoder.decode([CallRecord].self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    /// Dettaglio completo di una chiamata (trascrizione, mappa, eventi)
    public func fetchCallDetail(id: String) async throws -> CallRecord {
        let request = try makeRequest(endpoint: "/api/calls/\(id)")
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw APIError.unknown
        }
        guard (200...299).contains(http.statusCode) else {
            let msg = String(data: data, encoding: .utf8) ?? "Errore HTTP"
            throw APIError.serverError(statusCode: http.statusCode, message: msg)
        }

        do {
            let decoder = JSONDecoder()
            return try decoder.decode(CallRecord.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    /// URL di streaming audio per AVPlayer
    public func getAudioURL(callId: String) -> URL? {
        return URL(string: "\(settings.cleanServerURL)/api/calls/\(callId)/audio?token=\(settings.apiToken)")
    }

    /// Verifica lo stato del server (Health Check)
    public func checkHealth() async throws -> (success: Bool, message: String) {
        guard let url = URL(string: "\(settings.cleanServerURL)/api/health") else {
            return (false, "Indirizzo URL non valido: \(settings.cleanServerURL)")
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 10.0
        request.setValue("Bearer \(settings.apiToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            return (false, "Nessuna risposta HTTP ricevuta dal server.")
        }

        guard (200...299).contains(http.statusCode) else {
            return (false, "Errore HTTP \(http.statusCode): il server ha risposto con codice anomalo.")
        }

        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let status = json["status"] as? String {
            if status.lowercased() == "ok" {
                let model = json["gemini_model"] as? String ?? "gemini-2.5-flash"
                return (true, "Connessione riuscita! VPS e \(model) operativi.")
            } else {
                return (false, "Il server ha risposto con status: \(status)")
            }
        }
        return (true, "Connessione riuscita! Backend VPS online.")
    }

    /// Richiede la rielaborazione AI della chiamata
    public func reprocessCall(id: String) async throws -> Bool {
        let request = try makeRequest(endpoint: "/api/calls/\(id)/reprocess", method: "POST")
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            return false
        }
        return true
    }
}
