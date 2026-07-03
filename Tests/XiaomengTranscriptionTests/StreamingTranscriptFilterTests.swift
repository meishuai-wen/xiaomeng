import XCTest
@testable import XiaomengTranscription

final class StreamingTranscriptFilterTests: XCTestCase {
    func testIgnoresWhisperRuntimeLogs() {
        var filter = StreamingTranscriptFilter()

        XCTAssertNil(filter.nextText(from: "load_backend: loaded MTL backend"))
        XCTAssertNil(filter.nextText(from: "ggml_metal_init: using embedded metal library"))
        XCTAssertNil(filter.nextText(from: "whisper_init_from_file_with_params_no_state: loading model"))
    }

    func testStripsTimestampsFromTranscriptLine() {
        var filter = StreamingTranscriptFilter()

        let text = filter.nextText(from: "[00:00:00.000 --> 00:00:01.000]  你好 Xiaomeng")

        XCTAssertEqual(text, "你好 Xiaomeng")
    }

    func testEmitsOnlyNewSuffixForRepeatedPartialTranscript() {
        var filter = StreamingTranscriptFilter()

        XCTAssertEqual(filter.nextText(from: "你好"), "你好")
        XCTAssertEqual(filter.nextText(from: "你好世界"), "世界")
        XCTAssertNil(filter.nextText(from: "你好世界"))
    }
}
