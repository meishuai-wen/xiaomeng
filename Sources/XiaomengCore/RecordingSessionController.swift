public enum RecordingMode: Equatable, Sendable {
    case toggle
    case pushToTalk
}

public enum RecordingSessionState: Equatable, Sendable {
    case idle
    case toggleRecording
    case pushToTalkRecording
    case transcribing
}

public enum RecordingSessionInput: Equatable, Sendable {
    case toggleHotkeyPressed
    case pushToTalkPressed
    case pushToTalkReleased
    case transcriptionFinished
    case transcriptionFailed
}

public enum RecordingSessionAction: Equatable, Sendable {
    case startRecording(mode: RecordingMode)
    case stopRecordingAndTranscribe
    case ignore
}

public struct RecordingSessionOutput: Equatable, Sendable {
    public let action: RecordingSessionAction
    public let assistantEvent: AssistantEvent?

    public init(action: RecordingSessionAction, assistantEvent: AssistantEvent?) {
        self.action = action
        self.assistantEvent = assistantEvent
    }
}

public final class RecordingSessionController {
    public private(set) var state: RecordingSessionState

    public init(initialState: RecordingSessionState = .idle) {
        self.state = initialState
    }

    public func handle(_ input: RecordingSessionInput) -> RecordingSessionOutput {
        switch (state, input) {
        case (.idle, .toggleHotkeyPressed):
            state = .toggleRecording
            return RecordingSessionOutput(action: .startRecording(mode: .toggle), assistantEvent: .toggleRecordingStarted)

        case (.toggleRecording, .toggleHotkeyPressed):
            state = .transcribing
            return RecordingSessionOutput(action: .stopRecordingAndTranscribe, assistantEvent: .recordingStopped)

        case (.idle, .pushToTalkPressed):
            state = .pushToTalkRecording
            return RecordingSessionOutput(action: .startRecording(mode: .pushToTalk), assistantEvent: .pushToTalkStarted)

        case (.pushToTalkRecording, .pushToTalkReleased):
            state = .transcribing
            return RecordingSessionOutput(action: .stopRecordingAndTranscribe, assistantEvent: .recordingStopped)

        case (.transcribing, .transcriptionFinished):
            state = .idle
            return RecordingSessionOutput(action: .ignore, assistantEvent: .transcriptionSucceeded)

        case (.transcribing, .transcriptionFailed):
            state = .idle
            return RecordingSessionOutput(action: .ignore, assistantEvent: .transcriptionEmpty)

        default:
            return RecordingSessionOutput(action: .ignore, assistantEvent: nil)
        }
    }
}
