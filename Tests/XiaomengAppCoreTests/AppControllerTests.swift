import Foundation
import XCTest
@testable import XiaomengAppCore
@testable import XiaomengAudio
@testable import XiaomengCore
@testable import XiaomengTranscription

@MainActor
final class AppControllerTests: XCTestCase {
    func testToggleRecordingStartsAudioAndUpdatesAssistantState() throws {
        let recorder = FakeAudioRecorder()
        let controller = AppController(audioRecorder: recorder)

        try controller.toggleRecording()

        XCTAssertEqual(recorder.startedModes, [.toggle])
        XCTAssertEqual(controller.recordingState, .toggleRecording)
        XCTAssertEqual(controller.assistantState, .listening)
        XCTAssertEqual(controller.lastRecordingURL?.lastPathComponent, "fake.wav")
    }

    func testSecondToggleStopsAudioAndMovesToTranscribing() throws {
        let recorder = FakeAudioRecorder()
        let controller = AppController(audioRecorder: recorder)

        try controller.toggleRecording()
        try controller.toggleRecording()

        XCTAssertEqual(recorder.stopCount, 1)
        XCTAssertEqual(controller.recordingState, .transcribing)
        XCTAssertEqual(controller.assistantState, .transcribing)
    }

    func testTranscriptionCompletionMovesAssistantToSuccess() throws {
        let recorder = FakeAudioRecorder()
        let controller = AppController(audioRecorder: recorder)

        try controller.toggleRecording()
        try controller.toggleRecording()
        controller.finishTranscription(success: true)

        XCTAssertEqual(controller.recordingState, .idle)
        XCTAssertEqual(controller.assistantState, .success)
    }

    func testCompletedTranscriptionWritesMarkdownLog() throws {
        let directory = try makeTemporaryDirectory()
        let recorder = FakeAudioRecorder()
        let controller = AppController(
            audioRecorder: recorder,
            markdownLogStore: MarkdownLogStore(directory: directory)
        )
        let date = try XCTUnwrap(makeDate(year: 2026, month: 7, day: 2, hour: 16, minute: 8))

        try controller.completeTranscription(text: "你好 Xiaomeng", at: date)

        let markdownURL = try XCTUnwrap(controller.lastMarkdownURL)
        XCTAssertEqual(markdownURL.lastPathComponent, "2026-07-02.md")
        let content = try String(contentsOf: markdownURL, encoding: .utf8)
        XCTAssertEqual(content, "## 16:08\n\n你好 Xiaomeng\n\n")
        XCTAssertEqual(controller.assistantState, .success)
    }

    func testCompletedTranscriptionOutputsTrimmedText() throws {
        let directory = try makeTemporaryDirectory()
        let recorder = FakeAudioRecorder()
        let textOutput = FakeTextOutput()
        let controller = AppController(
            audioRecorder: recorder,
            textOutput: textOutput,
            markdownLogStore: MarkdownLogStore(directory: directory)
        )

        try controller.completeTranscription(text: "  你好 Xiaomeng  ", at: Date())

        XCTAssertEqual(textOutput.outputTexts, ["你好 Xiaomeng"])
        XCTAssertEqual(controller.assistantState, .success)
    }

    func testEmptyTranscriptionDoesNotWriteMarkdownLog() throws {
        let directory = try makeTemporaryDirectory()
        let recorder = FakeAudioRecorder()
        let controller = AppController(
            audioRecorder: recorder,
            markdownLogStore: MarkdownLogStore(directory: directory)
        )

        try controller.completeTranscription(text: "   ", at: Date())

        XCTAssertNil(controller.lastMarkdownURL)
        XCTAssertEqual(controller.assistantState, .error)
    }

    func testEmptyTranscriptionDoesNotOutputText() throws {
        let directory = try makeTemporaryDirectory()
        let recorder = FakeAudioRecorder()
        let textOutput = FakeTextOutput()
        let controller = AppController(
            audioRecorder: recorder,
            textOutput: textOutput,
            markdownLogStore: MarkdownLogStore(directory: directory)
        )

        try controller.completeTranscription(text: "   ", at: Date())

        XCTAssertTrue(textOutput.outputTexts.isEmpty)
        XCTAssertEqual(controller.assistantState, .error)
    }

    func testTranscribesLatestRecordingAndWritesMarkdown() throws {
        let directory = try makeTemporaryDirectory()
        let recorder = FakeAudioRecorder()
        let transcriber = FakeTranscriber(text: "转写文本")
        let controller = AppController(
            audioRecorder: recorder,
            transcriber: transcriber,
            markdownLogStore: MarkdownLogStore(directory: directory)
        )

        try controller.toggleRecording()
        try controller.toggleRecording()
        try controller.transcribeLatestRecording()

        XCTAssertEqual(transcriber.lastAudioURL?.lastPathComponent, "fake.wav")
        let markdownURL = try XCTUnwrap(controller.lastMarkdownURL)
        let content = try String(contentsOf: markdownURL, encoding: .utf8)
        XCTAssertTrue(content.contains("转写文本"))
        XCTAssertEqual(controller.assistantState, .success)
    }

    private func makeTemporaryDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("xiaomeng-app-controller-tests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private func makeDate(year: Int, month: Int, day: Int, hour: Int, minute: Int) -> Date? {
        var components = DateComponents()
        components.calendar = Calendar(identifier: .gregorian)
        components.timeZone = TimeZone(secondsFromGMT: 0)
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        return components.date
    }
}

@MainActor
private final class FakeAudioRecorder: AudioRecording {
    private(set) var startedModes: [RecordingMode] = []
    private(set) var stopCount = 0
    private(set) var isRecording = false

    func start(mode: RecordingMode) throws -> URL {
        startedModes.append(mode)
        isRecording = true
        return URL(fileURLWithPath: "/tmp/fake.wav")
    }

    func stop() throws -> URL {
        stopCount += 1
        isRecording = false
        return URL(fileURLWithPath: "/tmp/fake.wav")
    }
}

private final class FakeTranscriber: Transcribing {
    private let text: String
    private(set) var lastAudioURL: URL?

    init(text: String) {
        self.text = text
    }

    func transcribe(audioURL: URL) throws -> String {
        lastAudioURL = audioURL
        return text
    }
}

private final class FakeTextOutput: TextOutputting {
    private(set) var outputTexts: [String] = []

    func output(_ text: String) throws {
        outputTexts.append(text)
    }
}
