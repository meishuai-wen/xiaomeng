import Foundation

public struct StreamingTranscriptFilter: Sendable {
    private var lastTranscript = ""

    public init() {}

    public mutating func nextText(from rawLine: String) -> String? {
        let text = Self.clean(rawLine)
        guard !text.isEmpty, !Self.isRuntimeLog(text) else {
            return nil
        }

        if text == lastTranscript {
            return nil
        }

        if text.hasPrefix(lastTranscript) {
            let suffix = String(text.dropFirst(lastTranscript.count))
                .trimmingCharacters(in: .whitespacesAndNewlines)
            lastTranscript = text
            return suffix.isEmpty ? nil : suffix
        }

        lastTranscript = text
        return text
    }

    private static func clean(_ rawLine: String) -> String {
        rawLine
            .replacingOccurrences(
                of: #"\u{001B}\[[0-9;]*[A-Za-z]"#,
                with: "",
                options: .regularExpression
            )
            .replacingOccurrences(
                of: #"^\[[0-9:. ]+-->[0-9:. ]+\]\s*"#,
                with: "",
                options: .regularExpression
            )
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func isRuntimeLog(_ text: String) -> Bool {
        let prefixes = [
            "load_",
            "ggml_",
            "whisper_",
            "main:",
            "init:",
            "system_info:",
            "sampling:",
            "processing"
        ]

        return prefixes.contains { text.hasPrefix($0) }
    }
}
