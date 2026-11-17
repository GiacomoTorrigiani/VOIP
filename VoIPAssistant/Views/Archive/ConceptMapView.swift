import SwiftUI

public struct ConceptMapView: View {
    let conceptMap: ConceptMap?
    @State private var viewMode: Int = 0 // 0: Grafo Cmap, 1: Mermaid
    @State private var exportedImage: UIImage? = nil
    @State private var isShowingShareSheet: Bool = false
    @State private var hasCopiedMermaid: Bool = false

    public init(conceptMap: ConceptMap?) {
        self.conceptMap = conceptMap
    }

    public var body: some View {
        VStack(spacing: 12) {
            // Header con selettore visualizzazione ed esportazione
            HStack {
                Picker("Modalità", selection: $viewMode) {
                    Text("Grafo Cmap").tag(0)
                    Text("Mermaid").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())

                if viewMode == 1, let mermaid = conceptMap?.mermaidCode, !mermaid.isEmpty {
                    Button(action: {
                        UIPasteboard.general.string = mermaid
                        hasCopiedMermaid = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            hasCopiedMermaid = false
                        }
                    }) {
                        Image(systemName: hasCopiedMermaid ? "checkmark" : "doc.on.doc")
                            .font(.subheadline)
                            .padding(8)
                            .background(Color.secondary.opacity(0.12))
                            .cornerRadius(8)
                    }
                }
            }

            if let map = conceptMap, (!map.concepts.isEmpty || map.mermaidCode != nil) {
                if viewMode == 0 {
                    // Vista Grafica CmapTools interattiva
                    ZStack {
                        ConceptMapWebView(conceptMap: map) { image in
                            self.exportedImage = image
                            self.isShowingShareSheet = true
                        }
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                        )
                    }
                    .frame(height: 380)
                } else {
                    // Vista Codice Mermaid
                    ScrollView {
                        Text(map.mermaidCode ?? "Codice Mermaid non disponibile")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(12)
                    }
                    .frame(height: 380)
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "point.3.connected.trianglepath.dotted")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    Text("Nessuna mappa concettuale generata per questa chiamata.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 250)
            }
        }
        .sheet(isPresented: $isShowingShareSheet) {
            if let img = exportedImage {
                ActivityViewController(activityItems: [img])
            }
        }
    }
}

private struct ActivityViewController: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
