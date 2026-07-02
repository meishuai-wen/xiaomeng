import Foundation
import XiaomengAudio
import XiaomengCore

@MainActor
public final class AppController {
    private let audioRecorder: AudioRecording
    private let recordingSessionController: RecordingSessionController
    private let assistantStateController: AssistantStateController

    public private(set) var lastRecordingURL: URL?

    public init(
        audioRecorder: AudioRecording,
        recordingSessionController: RecordingSessionController = RecordingSessionController(),
        assistantStateController: AssistantStateController = AssistantStateController(initialState: .idle)
    ) {
        self.audioRecorder = audioRecorder
        self.recordingSessionController = recordingSessionController
        self.assistantStateController = assistantStateController
    }

    public var recordingState: RecordingSessionState {
        recordingSessionController.state
    }

    public var assistantState: AssistantState {
        assistantStateController.currentState
    }

    public func toggleRecording() throws {
        let output = recordingSessionController.handle(.toggleHotkeyPressed)
        try perform(output)
    }

    public func pushToTalkStarted() throws {
        let output = recordingSessionController.handle(.pushToTalkPressed)
        try perform(output)
    }

    public func pushToTalkReleased() throws {
        let output = recordingSessionController.handle(.pushToTalkReleased)
        try perform(output)
    }

    public func finishTranscription(success: Bool) {
        let output = recordingSessionController.handle(success ? .transcriptionFinished : .transcriptionFailed)
        applyAssistantEvent(output.assistantEvent)
    }

    private func perform(_ output: RecordingSessionOutput) throws {
        switch output.action {
        case .startRecording(let mode):
            lastRecordingURL = try audioRecorder.start(mode: mode)
        case .stopRecordingAndTranscribe:
            lastRecordingURL = try audioRecorder.stop()
        case .ignore:
            break
        }

        applyAssistantEvent(output.assistantEvent)
    }

    private func applyAssistantEvent(_ event: AssistantEvent?) {
        guard let event else {
            return
        }

        assistantStateController.handle(event)
    }
}
