import SwiftUI

public struct TranscriptionView: View {
    let transcription: String
    @State private var hasCopied: Bool = false

    public init(transcription: String) {
        self.transcription = transcription
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Action bar: Copia & Condividi
            HStack {
                Text("TRASCRIZIONE AUDIO")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)

                Spacer()

                Button(action: {
                    UIPasteboard.general.string = transcription
                    hasCopied = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        hasCopied = false
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: hasCopied ? "checkmark" : "doc.on.doc")
                        Text(hasCopied ? "Copiata" : "Copia")
                    }
                    .font(.caption.bold())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.secondary.opacity(0.12))
                    .cornerRadius(8)
                }

                ShareLink(item: transcription) {
                    HStack(spacing: 4) {
                        Image(systemName: "square.and.arrow.up")
                        Text("Condividi")
                    }
                    .font(.caption.bold())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.secondary.opacity(0.12))
                    .cornerRadius(8)
                }
            }

            if transcription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "text.bubble")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("Nessuna trascrizione disponibile per questa chiamata.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                // Formatta il testo suddividendolo in battute o paragrafi
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(parseDialogue(transcription), id: \.id) { item in
                        DialogueBubbleView(item: item)
                    }
                }
            }
        }
    }

    private func parseDialogue(_ text: String) -> [DialogueItem] {
        let lines = text.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        var result: [DialogueItem] = []

        for line in lines {
            if line.contains(":") {
                let parts = line.split(separator: ":", maxSplits: 1).map(String.init)
                let speaker = parts[0].trimmingCharacters(in: .whitespaces)
                let content = parts.count > 1 ? parts[1].trimmingCharacters(in: .whitespaces) : ""
                let isMe = speaker.lowercased().contains("giacomo") || speaker.contains("3669650010") || speaker.lowercased().contains("io")
                result.append(DialogueItem(speaker: speaker, text: content, isMe: isMe))
            } else {
                result.append(DialogueItem(speaker: nil, text: line, isMe: false))
            }
        }

        if result.isEmpty {
            result.append(DialogueItem(speaker: nil, text: text, isMe: false))
        }
        return result
    }
}

private struct DialogueItem: Identifiable {
    let id = UUID()
    let speaker: String?
    let text: String
    let isMe: Bool
}

private struct DialogueBubbleView: View {
    let item: DialogueItem

    var body: some View {
        VStack(alignment: item.isMe ? .trailing : .leading, spacing: 4) {
            if let speaker = item.speaker {
                Text(speaker)
                    .font(.caption2.bold())
                    .foregroundColor(item.isMe ? .blue : .purple)
                    .padding(.horizontal, 4)
            }

            Text(item.text)
                .font(.body)
                .foregroundColor(.primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    item.isMe
                        ? Color.blue.opacity(0.12)
                        : Color(UIColor.secondarySystemBackground)
                )
                .cornerRadius(12)
        }
        .frame(maxWidth: .infinity, alignment: item.isMe ? .trailing : .leading)
    }
}
