import Foundation

public struct WhisperCLIConfiguration: Equatable, Sendable {
    public let executableURL: URL
    public let modelURL: URL
    public let language: String

    public init(
        executableURL: URL,
        modelURL: URL,
        language: String = "auto"
    ) {
        self.executableURL = executableURL
        self.modelURL = modelURL
        self.language = language
    }

    public func arguments(for audioURL: URL) -> [String] {
        [
            "-m", modelURL.path,
            "-f", audioURL.path,
            "-l", language,
            "--no-timestamps"
        ]
    }
}

