import SwiftUI
import WebKit

public struct ConceptMapWebView: UIViewRepresentable {
    let conceptMap: ConceptMap?
    var onExportImage: ((UIImage) -> Void)?

    public init(conceptMap: ConceptMap?, onExportImage: ((UIImage) -> Void)? = nil) {
        self.conceptMap = conceptMap
        self.onExportImage = onExportImage
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    public func makeUIView(context: Context) -> WKWebView {
        let contentController = WKUserContentController()
        contentController.add(context.coordinator, name: "exportImage")

        let config = WKWebViewConfiguration()
        config.userContentController = contentController

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false // Cytoscape gestisce il proprio canvas

        // Carica il template HTML dalle risorse dell'app o da stringa
        if let templateURL = Bundle.main.url(forResource: "cmap_template", withExtension: "html") {
            webView.loadFileURL(templateURL, allowingReadAccessTo: templateURL.deletingLastPathComponent())
        } else {
            // Fallback con template inline se il bundle URL non è ancora caricato
            let fallbackHTML = defaultTemplateHTML()
            webView.loadHTMLString(fallbackHTML, baseURL: URL(string: "https://cdn.jsdelivr.net"))
        }

        context.coordinator.webView = webView
        return webView
    }

    public func updateUIView(_ webView: WKWebView, context: Context) {
        context.coordinator.parent = self
        if context.coordinator.isPageLoaded {
            context.coordinator.injectData()
        }
    }

    public class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var parent: ConceptMapWebView
        weak var webView: WKWebView?
        var isPageLoaded = false

        init(_ parent: ConceptMapWebView) {
            self.parent = parent
        }

        public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            isPageLoaded = true
            injectData()
        }

        func injectData() {
            guard let map = parent.conceptMap, let webView = webView else { return }
            let jsonString = map.jsonStringForWeb
            // Esegui la funzione Javascript nel template
            let js = "if (typeof renderMap === 'function') { renderMap(\(jsonString)); }"
            webView.evaluateJavaScript(js, completionHandler: nil)
        }

        public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "exportImage", let base64String = message.body as? String {
                // Rimuovi eventuale prefisso data:image/png;base64,
                let cleanBase64 = base64String.components(separatedBy: ",").last ?? base64String
                if let data = Data(base64Encoded: cleanBase64), let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self.parent.onExportImage?(image)
                    }
                }
            }
        }
    }

    private func defaultTemplateHTML() -> String {
        return """
        <!DOCTYPE html>
        <html>
        <head>
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <script src="https://cdn.jsdelivr.net/npm/cytoscape@3.28.1/dist/cytoscape.min.js"></script>
          <style>
            body, html { margin:0; padding:0; width:100%; height:100%; overflow:hidden; background:#f8fafc; }
            #cy { width:100%; height:100%; }
          </style>
        </head>
        <body>
          <div id="cy"></div>
          <script>
            var cy = null;
            function renderMap(data) {
              var elems = [];
              if (data.concepts) {
                data.concepts.forEach(function(c){ elems.push({ data: { id: c.id, label: c.label } }); });
              }
              if (data.linking_phrases) {
                data.linking_phrases.forEach(function(l, i){
                  elems.push({ data: { id: 'e'+i, source: l.from, target: l.to, label: l.label } });
                });
              }
              cy = cytoscape({
                container: document.getElementById('cy'),
                elements: elems,
                style: [
                  { selector: 'node', style: { 'shape': 'round-rectangle', 'background-color': '#fff', 'border-color': '#0284c7', 'border-width': 2, 'label': 'data(label)', 'padding': '10px' } },
                  { selector: 'edge', style: { 'width': 2, 'line-color': '#94a3b8', 'target-arrow-shape': 'triangle', 'curve-style': 'bezier', 'label': 'data(label)' } }
                ],
                layout: { name: 'breadthfirst', directed: true, padding: 30 }
              });
            }
          </script>
        </body>
        </html>
        """
    }
}
