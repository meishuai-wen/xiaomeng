import XCTest
@testable import XiaomengCore

final class AssistantStateControllerTests: XCTestCase {
    func testInitialStateIsLoadingModel() {
        let controller = AssistantStateController()

        XCTAssertEqual(controller.currentState, .loadingModel)
    }

    func testModelLoadedMovesToIdle() {
        let controller = AssistantStateController()

        controller.handle(.modelLoaded)

        XCTAssertEqual(controller.currentState, .idle)
    }

    func testToggleRecordingMovesThroughListeningAndTranscribing() {
        let controller = AssistantStateController(initialState: .idle)

        controller.handle(.toggleRecordingStarted)
        XCTAssertEqual(controller.currentState, .listening)

        controller.handle(.recordingStopped)
        XCTAssertEqual(controller.currentState, .transcribing)
    }

    func testPushToTalkUsesDedicatedState() {
        let controller = AssistantStateController(initialState: .idle)

        controller.handle(.pushToTalkStarted)
        XCTAssertEqual(controller.currentState, .pushToTalk)
    }

    func testSuccessAndEmptyTranscriptionReturnToExpectedStates() {
        let controller = AssistantStateController(initialState: .transcribing)

        controller.handle(.transcriptionSucceeded)
        XCTAssertEqual(controller.currentState, .success)

        controller.handle(.returnToIdle)
        XCTAssertEqual(controller.currentState, .idle)

        controller.handle(.recordingStopped)
        controller.handle(.transcriptionEmpty)
        XCTAssertEqual(controller.currentState, .error)
    }

    func testPermissionMissingOverridesCurrentState() {
        let controller = AssistantStateController(initialState: .listening)

        controller.handle(.permissionMissing)

        XCTAssertEqual(controller.currentState, .permission)
    }
}
