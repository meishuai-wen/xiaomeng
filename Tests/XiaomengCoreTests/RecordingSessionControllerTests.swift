import XCTest
@testable import XiaomengCore

final class RecordingSessionControllerTests: XCTestCase {
    func testToggleHotkeyStartsAndStopsRecording() {
        let controller = RecordingSessionController()

        let start = controller.handle(.toggleHotkeyPressed)
        XCTAssertEqual(start, RecordingSessionOutput(action: .startRecording(mode: .toggle), assistantEvent: .toggleRecordingStarted))
        XCTAssertEqual(controller.state, .toggleRecording)

        let stop = controller.handle(.toggleHotkeyPressed)
        XCTAssertEqual(stop, RecordingSessionOutput(action: .stopRecordingAndTranscribe, assistantEvent: .recordingStopped))
        XCTAssertEqual(controller.state, .transcribing)
    }

    func testPushToTalkStartsOnPressAndStopsOnRelease() {
        let controller = RecordingSessionController()

        let start = controller.handle(.pushToTalkPressed)
        XCTAssertEqual(start, RecordingSessionOutput(action: .startRecording(mode: .pushToTalk), assistantEvent: .pushToTalkStarted))
        XCTAssertEqual(controller.state, .pushToTalkRecording)

        let stop = controller.handle(.pushToTalkReleased)
        XCTAssertEqual(stop, RecordingSessionOutput(action: .stopRecordingAndTranscribe, assistantEvent: .recordingStopped))
        XCTAssertEqual(controller.state, .transcribing)
    }

    func testTranscriptionFinishedReturnsToIdleWithSuccess() {
        let controller = RecordingSessionController(initialState: .transcribing)

        let output = controller.handle(.transcriptionFinished)

        XCTAssertEqual(output, RecordingSessionOutput(action: .ignore, assistantEvent: .transcriptionSucceeded))
        XCTAssertEqual(controller.state, .idle)
    }

    func testTranscriptionFailedReturnsToIdleWithError() {
        let controller = RecordingSessionController(initialState: .transcribing)

        let output = controller.handle(.transcriptionFailed)

        XCTAssertEqual(output, RecordingSessionOutput(action: .ignore, assistantEvent: .transcriptionEmpty))
        XCTAssertEqual(controller.state, .idle)
    }

    func testInvalidInputsAreIgnoredWithoutChangingState() {
        let controller = RecordingSessionController(initialState: .toggleRecording)

        let output = controller.handle(.pushToTalkPressed)

        XCTAssertEqual(output, RecordingSessionOutput(action: .ignore, assistantEvent: nil))
        XCTAssertEqual(controller.state, .toggleRecording)
    }
}
