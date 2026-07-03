import Foundation

public struct WhisperStreamConfiguration: Equatable, Sendable {
    public let executableURL: URL
    public let modelURL: URL
    public let language: String
    public let stepMilliseconds: Int
    public let lengthMilliseconds: Int
    public let keepMilliseconds: Int

    public init(
        executableURL: URL,
        modelURL: URL,
        language: String = "auto",
        stepMilliseconds: Int = 1500,
        lengthMilliseconds: Int = 5000,
        keepMilliseconds: Int = 300
    ) {
        self.executableURL = executableURL
        self.modelURL = modelURL
        self.language = language
        self.stepMilliseconds = stepMilliseconds
        self.lengthMilliseconds = lengthMilliseconds
        self.keepMilliseconds = keepMilliseconds
    }

    public var arguments: [String] {
        [
            "-m", modelURL.path,
            "-l", language,
            "--step", String(stepMilliseconds),
            "--length", String(lengthMilliseconds),
            "--keep", String(keepMilliseconds)
        ]
    }
}
