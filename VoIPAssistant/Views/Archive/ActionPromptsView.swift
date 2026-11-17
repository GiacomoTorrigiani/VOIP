import SwiftUI

public struct ActionPromptsView: View {
    let prompts: [ActionPrompt]
    @State private var copiedPromptId: String? = nil

    public init(prompts: [ActionPrompt]) {
        self.prompts = prompts
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("RICHIESTE & PROMPT AI OPERATIVI")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
                Spacer()
            }

            if prompts.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "sparkles.rectangle.stack")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    Text("Nessuna richiesta o compito rilevato in questa conversazione.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("Quando durante la chiamata l'interlocutore ti chiede di fare qualcosa (es. un dossier, un'analisi o un documento), l'AI genererà qui il prompt pronto.")
                        .font(.caption)
                        .foregroundColor(.secondary.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                ForEach(prompts) { prompt in
                    ActionPromptCard(
                        prompt: prompt,
                        isCopied: copiedPromptId == prompt.id,
                        onCopy: {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            UIPasteboard.general.string = prompt.promptText
                            copiedPromptId = prompt.id
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                if copiedPromptId == prompt.id {
                                    copiedPromptId = nil
                                }
                            }
                        }
                    )
                }
            }
        }
    }
}

private struct ActionPromptCard: View {
    let prompt: ActionPrompt
    let isCopied: Bool
    let onCopy: () -> Void

    private var modeBadgeInfo: (text: String, icon: String, color: Color) {
        let m = prompt.suggestedMode.lowercased()
        if m.contains("deep_research") || m.contains("research") {
            return ("Deep Research", "magnifyingglass.circle.fill", .indigo)
        } else if m.contains("document") || m.contains("file") || m.contains("analisi") {
            return ("Analisi Documento", "doc.text.fill", .orange)
        } else if m.contains("draft") || m.contains("stesura") {
            return ("Stesura Rapida", "bolt.fill", .green)
        } else {
            return ("Prompt AI", "sparkles", .purple)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header: Badges Modalità e Modello
            HStack(spacing: 8) {
                let badge = modeBadgeInfo
                HStack(spacing: 4) {
                    Image(systemName: badge.icon)
                        .font(.caption2.bold())
                    Text(badge.text)
                        .font(.caption2.bold())
                }
                .foregroundColor(badge.color)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(badge.color.opacity(0.15))
                .cornerRadius(6)

                HStack(spacing: 4) {
                    Image(systemName: "cpu")
                        .font(.caption2.bold())
                    Text(prompt.suggestedModel)
                        .font(.caption2.bold())
                }
                .foregroundColor(.blue)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.15))
                .cornerRadius(6)

                Spacer()
            }

            // Titolo Task
            Text(prompt.taskTitle)
                .font(.headline)
                .foregroundColor(.primary)

            // Contesto della richiesta nella telefonata
            if !prompt.requestContext.isEmpty {
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "quote.opening")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(prompt.requestContext)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                }
            }

            // Box con Prompt Ingegnerizzato
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("PROMPT PRONTO PER L'AI")
                        .font(.caption2.bold())
                        .foregroundColor(.secondary)
                    Spacer()
                    ShareLink(item: prompt.promptText) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Text(prompt.promptText)
                    .font(.system(.footnote, design: .monospaced))
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .background(Color(UIColor.tertiarySystemGroupedBackground))
                    .cornerRadius(8)
            }

            Divider()

            // Pulsanti di Azione
            VStack(spacing: 8) {
                // Copia Prompt
                Button(action: onCopy) {
                    HStack(spacing: 8) {
                        Image(systemName: isCopied ? "checkmark.circle.fill" : "doc.on.doc")
                            .font(.subheadline.bold())
                        Text(isCopied ? "Prompt Copiato negli Appunti!" : "Copia Prompt Pronto")
                            .font(.subheadline.bold())
                    }
                    .foregroundColor(isCopied ? .green : .white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(isCopied ? Color.green.opacity(0.15) : Color.blue)
                    .cornerRadius(10)
                }

                // Apri in Gemini Web (Gemini Pro / Deep Research)
                Button(action: {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    if let url = URL(string: "https://gemini.google.com/app") {
                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.subheadline.bold())
                        Text("Apri in Google Gemini (Pro / Deep Research)")
                            .font(.subheadline.bold())
                    }
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color(UIColor.tertiarySystemGroupedBackground))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                    )
                }
            }
        }
        .padding(14)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.purple.opacity(0.2), lineWidth: 1)
        )
    }
}
