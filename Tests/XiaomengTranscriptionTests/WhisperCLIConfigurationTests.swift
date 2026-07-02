import Foundation
import XCTest
@testable import XiaomengTranscription

final class WhisperCLIConfigurationTests: XCTestCase {
    func testBuildsArgumentsForWhisperCLI() {
        let configuration = WhisperCLIConfiguration(
            executableURL: URL(fileURLWithPath: "/usr/local/bin/whisper-cli"),
            modelURL: URL(fileURLWithPath: "/models/ggml-small.bin"),
            language: "auto"
        )
        let audioURL = URL(fileURLWithPath: "/tmp/input.wav")

        XCTAssertEqual(configuration.arguments(for: audioURL), [
            "-m", "/models/ggml-small.bin",
            "-f", "/tmp/input.wav",
            "-l", "auto",
            "--no-timestamps"
        ])
    }
}

