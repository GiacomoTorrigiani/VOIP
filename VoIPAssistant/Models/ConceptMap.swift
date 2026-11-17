import Foundation

public struct ConceptNode: Identifiable, Codable, Equatable, Hashable {
    public var id: String
    public var label: String

    public init(id: String, label: String) {
        self.id = id
        self.label = label
    }
}

public struct LinkingPhrase: Identifiable, Codable, Equatable, Hashable {
    public var id: String { "\(from)_\(to)_\(label)" }
    public var from: String
    public var to: String
    public var label: String

    enum CodingKeys: String, CodingKey {
        case from
        case to
        case source
        case target
        case label
        case phrase
    }

    public init(from: String, to: String, label: String) {
        self.from = from
        self.to = to
        self.label = label
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let s = (try? container.decode(String.self, forKey: .from)) ?? (try? container.decode(String.self, forKey: .source)) ?? ""
        let t = (try? container.decode(String.self, forKey: .to)) ?? (try? container.decode(String.self, forKey: .target)) ?? ""
        let l = (try? container.decode(String.self, forKey: .label)) ?? (try? container.decode(String.self, forKey: .phrase)) ?? ""
        self.from = s
        self.to = t
        self.label = l
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(from, forKey: .from)
        try container.encode(to, forKey: .to)
        try container.encode(label, forKey: .label)
    }
}

public struct ConceptMap: Codable, Equatable {
    public var concepts: [ConceptNode]
    public var linkingPhrases: [LinkingPhrase]
    public var mermaidCode: String?
    public var rawJSONString: String?

    enum CodingKeys: String, CodingKey {
        case concepts
        case linkingPhrases = "linking_phrases"
        case mermaidCode = "mermaid_code"
    }

    public init(concepts: [ConceptNode] = [], linkingPhrases: [LinkingPhrase] = [], mermaidCode: String? = nil) {
        self.concepts = concepts
        self.linkingPhrases = linkingPhrases
        self.mermaidCode = mermaidCode
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.concepts = (try? container.decode([ConceptNode].self, forKey: .concepts)) ?? []
        self.linkingPhrases = (try? container.decode([LinkingPhrase].self, forKey: .linkingPhrases)) ?? []
        self.mermaidCode = try? container.decodeIfPresent(String.self, forKey: .mermaidCode)
    }

    /// Produce una stringa JSON per passare i dati al template WKWebView
    public var jsonStringForWeb: String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .withoutEscapingSlashes
        if let data = try? encoder.encode(self), let str = String(data: data, encoding: .utf8) {
            return str
        }
        return "{}"
    }
}
