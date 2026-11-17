import Foundation

public struct ActionPrompt: Identifiable, Codable, Equatable {
    public var id: String
    public var taskTitle: String
    public var requestContext: String
    public var suggestedMode: String
    public var suggestedModel: String
    public var promptText: String

    enum CodingKeys: String, CodingKey {
        case id
        case taskTitle = "task_title"
        case requestContext = "request_context"
        case suggestedMode = "suggested_mode"
        case suggestedModel = "suggested_model"
        case promptText = "prompt_text"
    }

    public init(
        id: String = UUID().uuidString,
        taskTitle: String,
        requestContext: String,
        suggestedMode: String,
        suggestedModel: String,
        promptText: String
    ) {
        self.id = id
        self.taskTitle = taskTitle
        self.requestContext = requestContext
        self.suggestedMode = suggestedMode
        self.suggestedModel = suggestedModel
        self.promptText = promptText
    }
}
