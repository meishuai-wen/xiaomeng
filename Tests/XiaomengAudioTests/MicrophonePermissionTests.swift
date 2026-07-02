import AVFoundation
import XCTest
@testable import XiaomengAudio

final class MicrophonePermissionTests: XCTestCase {
    func testMapsAVAuthorizationStatusToAppPermission() {
        XCTAssertEqual(MicrophonePermission(status: .authorized), .granted)
        XCTAssertEqual(MicrophonePermission(status: .denied), .denied)
        XCTAssertEqual(MicrophonePermission(status: .restricted), .restricted)
        XCTAssertEqual(MicrophonePermission(status: .notDetermined), .notDetermined)
    }
}
