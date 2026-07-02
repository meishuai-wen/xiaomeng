public enum AssistantState: String, Equatable, Sendable {
    case loadingModel
    case idle
    case listening
    case pushToTalk
    case transcribing
    case success
    case error
    case permission
}

public enum AssistantEvent: Equatable, Sendable {
    case modelLoaded
    case toggleRecordingStarted
    case pushToTalkStarted
    case recordingStopped
    case transcriptionSucceeded
    case transcriptionEmpty
    case permissionMissing
    case modelLoadFailed
    case returnToIdle
}

public final class AssistantStateController {
    public private(set) var currentState: AssistantState

    public init(initialState: AssistantState = .loadingModel) {
        self.currentState = initialState
    }

    public func handle(_ event: AssistantEvent) {
        switch event {
        case .modelLoaded:
            currentState = .idle
        case .toggleRecordingStarted:
            currentState = .listening
        case .pushToTalkStarted:
            currentState = .pushToTalk
        case .recordingStopped:
            currentState = .transcribing
        case .transcriptionSucceeded:
            currentState = .success
        case .transcriptionEmpty, .modelLoadFailed:
            currentState = .error
        case .permissionMissing:
            currentState = .permission
        case .returnToIdle:
            currentState = .idle
        }
    }
}
