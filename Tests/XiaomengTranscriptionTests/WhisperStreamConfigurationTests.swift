import Foundation
import XCTest
@testable import XiaomengTranscription

final class WhisperStreamConfigurationTests: XCTestCase {
    func testBuildsStreamingArguments() {
        let configuration = WhisperStreamConfiguration(
            executableURL: URL(fileURLWithPath: "/usr/local/bin/whisper-stream"),
            modelURL: URL(fileURLWithPath: "/models/ggml-small.bin"),
            language: "auto",
            stepMilliseconds: 1500,
            lengthMilliseconds: 5000,
            keepMilliseconds: 300
        )

        XCTAssertEqual(configuration.arguments, [
            "-m", "/models/ggml-small.bin",
            "-l", "auto",
            "--step", "1500",
            "--length", "5000",
            "--keep", "300"
        ])
    }
}
