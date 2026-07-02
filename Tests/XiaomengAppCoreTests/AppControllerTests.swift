import Foundation
import XCTest
@testable import XiaomengAppCore
@testable import XiaomengAudio
@testable import XiaomengCore

@MainActor
final class AppControllerTests: XCTestCase {
    func testToggleRecordingStartsAudioAndUpdatesAssistantState() throws {
        let recorder = FakeAudioRecorder()
        let controller = AppController(audioRecorder: recorder)

        try controller.toggleRecording()

        XCTAssertEqual(recorder.startedModes, [.toggle])
        XCTAssertEqual(controller.recordingState, .toggleRecording)
        XCTAssertEqual(controller.assistantState, .listening)
        XCTAssertEqual(controller.lastRecordingURL?.lastPathComponent, "fake.wav")
    }

    func testSecondToggleStopsAudioAndMovesToTranscribing() throws {
        let recorder = FakeAudioRecorder()
        let controller = AppController(audioRecorder: recorder)

        try controller.toggleRecording()
        try controller.toggleRecording()

        XCTAssertEqual(recorder.stopCount, 1)
        XCTAssertEqual(controller.recordingState, .transcribing)
        XCTAssertEqual(controller.assistantState, .transcribing)
    }

    func testTranscriptionCompletionMovesAssistantToSuccess() throws {
        let recorder = FakeAudioRecorder()
        let controller = AppController(audioRecorder: recorder)

        try controller.toggleRecording()
        try controller.toggleRecording()
        controller.finishTranscription(success: true)

        XCTAssertEqual(controller.recordingState, .idle)
        XCTAssertEqual(controller.assistantState, .success)
    }
}

@MainActor
private final class FakeAudioRecorder: AudioRecording {
    private(set) var startedModes: [RecordingMode] = []
    private(set) var stopCount = 0
    private(set) var isRecording = false

    func start(mode: RecordingMode) throws -> URL {
        startedModes.append(mode)
        isRecording = true
        return URL(fileURLWithPath: "/tmp/fake.wav")
    }

    func stop() throws -> URL {
        stopCount += 1
        isRecording = false
        return URL(fileURLWithPath: "/tmp/fake.wav")
    }
}
