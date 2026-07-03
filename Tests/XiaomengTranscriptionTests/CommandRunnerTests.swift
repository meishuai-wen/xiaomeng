import Foundation
import XCTest
@testable import XiaomengTranscription

final class CommandRunnerTests: XCTestCase {
    func testSuccessfulCommandReturnsStandardOutputOnly() throws {
        let runner = ProcessCommandRunner()

        let output = try runner.run(
            executableURL: URL(fileURLWithPath: "/bin/sh"),
            arguments: ["-c", "printf '转写文本'; printf '运行日志' >&2"]
        )

        XCTAssertEqual(output, "转写文本")
    }

    func testFailedCommandIncludesStandardErrorForDiagnostics() {
        let runner = ProcessCommandRunner()

        XCTAssertThrowsError(
            try runner.run(
                executableURL: URL(fileURLWithPath: "/bin/sh"),
                arguments: ["-c", "printf '部分输出'; printf '错误日志' >&2; exit 7"]
            )
        ) { error in
            XCTAssertEqual(error as? TranscriptionError, .commandFailed(status: 7, output: "部分输出\n错误日志"))
        }
    }
}
