import Foundation
import XCTest
@testable import XiaomengTranscription

final class WhisperCLITranscriberTests: XCTestCase {
    func testTranscribeReturnsTrimmedCommandOutput() throws {
        let runner = FakeCommandRunner(output: "  你好 Xiaomeng  \n")
        let transcriber = WhisperCLITranscriber(
            configuration: WhisperCLIConfiguration(
                executableURL: URL(fileURLWithPath: "/usr/local/bin/whisper-cli"),
                modelURL: URL(fileURLWithPath: "/models/ggml-small.bin")
            ),
            commandRunner: runner
        )

        let text = try transcriber.transcribe(audioURL: URL(fileURLWithPath: "/tmp/input.wav"))

        XCTAssertEqual(text, "你好 Xiaomeng")
        XCTAssertEqual(runner.lastExecutableURL?.path, "/usr/local/bin/whisper-cli")
    }

    func testEmptyOutputThrowsEmptyResult() {
        let runner = FakeCommandRunner(output: " \n ")
        let transcriber = WhisperCLITranscriber(
            configuration: WhisperCLIConfiguration(
                executableURL: URL(fileURLWithPath: "/usr/local/bin/whisper-cli"),
                modelURL: URL(fileURLWithPath: "/models/ggml-small.bin")
            ),
            commandRunner: runner
        )

        XCTAssertThrowsError(try transcriber.transcribe(audioURL: URL(fileURLWithPath: "/tmp/input.wav"))) { error in
            XCTAssertEqual(error as? TranscriptionError, .emptyResult)
        }
    }
}

private final class FakeCommandRunner: CommandRunning {
    private let output: String
    private(set) var lastExecutableURL: URL?

    init(output: String) {
        self.output = output
    }

    func run(executableURL: URL, arguments: [String]) throws -> String {
        lastExecutableURL = executableURL
        return output
    }
}

