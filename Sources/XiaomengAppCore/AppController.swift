import Foundation
import XiaomengAudio
import XiaomengCore
import XiaomengTranscription

@MainActor
public final class AppController {
    private let audioRecorder: AudioRecording
    private let recordingSessionController: RecordingSessionController
    private let assistantStateController: AssistantStateController
    private let transcriber: Transcribing?
    private let markdownLogStore: MarkdownLogStore

    public private(set) var lastRecordingURL: URL?
    public private(set) var lastMarkdownURL: URL?

    public init(
        audioRecorder: AudioRecording,
        transcriber: Transcribing? = nil,
        recordingSessionController: RecordingSessionController = RecordingSessionController(),
        assistantStateController: AssistantStateController = AssistantStateController(initialState: .idle),
        markdownLogStore: MarkdownLogStore = MarkdownLogStore(directory: AppController.defaultMarkdownDirectory)
    ) {
        self.audioRecorder = audioRecorder
        self.transcriber = transcriber
        self.recordingSessionController = recordingSessionController
        self.assistantStateController = assistantStateController
        self.markdownLogStore = markdownLogStore
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

    public func completeTranscription(text: String, at date: Date = Date()) throws {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else {
            completeTranscriptionState(success: false)
            return
        }

        lastMarkdownURL = try markdownLogStore.append(trimmedText, at: date)
        completeTranscriptionState(success: true)
    }

    public func transcribeLatestRecording(at date: Date = Date()) throws {
        guard let lastRecordingURL, let transcriber else {
            completeTranscriptionState(success: false)
            return
        }

        let text = try transcriber.transcribe(audioURL: lastRecordingURL)
        try completeTranscription(text: text, at: date)
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

    private func completeTranscriptionState(success: Bool) {
        let input: RecordingSessionInput = success ? .transcriptionFinished : .transcriptionFailed
        let fallbackEvent: AssistantEvent = success ? .transcriptionSucceeded : .transcriptionEmpty
        let output = recordingSessionController.handle(input)
        applyAssistantEvent(output.assistantEvent ?? fallbackEvent)
    }

    public static var defaultMarkdownDirectory: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Documents", isDirectory: true)
            .appendingPathComponent("SpeechNotes", isDirectory: true)
    }
}
