import Foundation
import XCTest
@testable import XiaomengAudio

final class AudioRecordingConfigurationTests: XCTestCase {
    func testCreatesWavURLInRecordingDirectory() {
        let directory = URL(fileURLWithPath: "/tmp/xiaomeng-recordings", isDirectory: true)
        let configuration = AudioRecordingConfiguration(recordingDirectory: directory)

        let url = configuration.makeRecordingURL(id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!)

        XCTAssertEqual(url.deletingLastPathComponent(), directory)
        XCTAssertEqual(url.lastPathComponent, "00000000-0000-0000-0000-000000000001.wav")
    }
}
