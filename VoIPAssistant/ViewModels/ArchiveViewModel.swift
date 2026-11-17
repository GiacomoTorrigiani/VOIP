import Foundation
import SwiftUI

@MainActor
public final class ArchiveViewModel: ObservableObject {
    @Published public var calls: [CallRecord] = []
    @Published public var selectedCall: CallRecord? = nil
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String? = nil
    @Published public var searchQuery: String = ""

    private let apiService = APIService.shared

    public init() {}

    public var filteredCalls: [CallRecord] {
        if searchQuery.trimmingCharacters(in: .whitespaces).isEmpty {
            return calls
        }
        let q = searchQuery.lowercased()
        return calls.filter { call in
            call.displayName.lowercased().contains(q) ||
            call.recipientNumber.contains(q) ||
            (call.transcription?.lowercased().contains(q) ?? false) ||
            (call.summary?.lowercased().contains(q) ?? false)
        }
    }

    public func loadCalls() async {
        isLoading = true
        errorMessage = nil
        do {
            let fetched = try await apiService.fetchCalls()
            self.calls = fetched
            self.isLoading = false
        } catch {
            self.isLoading = false
            self.errorMessage = error.localizedDescription
        }
    }

    public func refresh() async {
        await loadCalls()
    }

    public func loadCallDetail(id: String) async {
        do {
            let detail = try await apiService.fetchCallDetail(id: id)
            self.selectedCall = detail
            // Aggiorna anche la chiamata nell'elenco
            if let index = calls.firstIndex(where: { $0.id == id }) {
                calls[index] = detail
            }
        } catch {
            self.errorMessage = "Impossibile aggiornare dettaglio: \(error.localizedDescription)"
        }
    }

    public func reprocess(call: CallRecord) async {
        isLoading = true
        do {
            let success = try await apiService.reprocessCall(id: call.id)
            if success {
                await loadCallDetail(id: call.id)
            }
        } catch {
            self.errorMessage = "Errore durante la rielaborazione: \(error.localizedDescription)"
        }
        isLoading = false
    }
}
