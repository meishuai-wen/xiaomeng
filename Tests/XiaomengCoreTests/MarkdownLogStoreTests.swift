import Foundation
import XCTest
@testable import XiaomengCore

final class MarkdownLogStoreTests: XCTestCase {
    func testAppendCreatesDailyMarkdownFileWithTimestampHeading() throws {
        let directory = try makeTemporaryDirectory()
        let store = MarkdownLogStore(directory: directory)
        let date = try XCTUnwrap(makeDate(year: 2026, month: 7, day: 2, hour: 14, minute: 30))

        let fileURL = try store.append("你好 Xiaomeng", at: date)

        XCTAssertEqual(fileURL.lastPathComponent, "2026-07-02.md")
        let content = try String(contentsOf: fileURL, encoding: .utf8)
        XCTAssertEqual(content, "## 14:30\n\n你好 Xiaomeng\n\n")
    }

    func testAppendDoesNotOverwriteExistingContent() throws {
        let directory = try makeTemporaryDirectory()
        let store = MarkdownLogStore(directory: directory)
        let firstDate = try XCTUnwrap(makeDate(year: 2026, month: 7, day: 2, hour: 14, minute: 30))
        let secondDate = try XCTUnwrap(makeDate(year: 2026, month: 7, day: 2, hour: 14, minute: 32))

        let fileURL = try store.append("第一段", at: firstDate)
        _ = try store.append("second note", at: secondDate)

        let content = try String(contentsOf: fileURL, encoding: .utf8)
        XCTAssertEqual(content, "## 14:30\n\n第一段\n\n## 14:32\n\nsecond note\n\n")
    }

    private func makeTemporaryDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("xiaomeng-tests-\(UUID().uuidString)", isDirectory: true)
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
