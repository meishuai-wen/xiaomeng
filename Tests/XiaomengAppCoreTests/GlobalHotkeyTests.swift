import XCTest
@testable import XiaomengAppCore

final class GlobalHotkeyTests: XCTestCase {
    func testToggleRecordingHotkeyUsesCommandShiftSpace() {
        let hotkey = GlobalHotkey.toggleRecording

        XCTAssertEqual(hotkey.displayName, "Command+Shift+Space")
        XCTAssertEqual(hotkey.actionTitle, "开始或停止录音")
    }
}
