import Foundation

public struct WhisperCLITranscriber: Transcribing {
    private let configuration: WhisperCLIConfiguration
    private let commandRunner: CommandRunning

    public init(
        configuration: WhisperCLIConfiguration,
        commandRunner: CommandRunning = ProcessCommandRunner()
    ) {
        self.configuration = configuration
        self.commandRunner = commandRunner
    }

    public func transcribe(audioURL: URL) throws -> String {
        let output = try commandRunner.run(
            executableURL: configuration.executableURL,
            arguments: configuration.arguments(for: audioURL)
        )
        let text = output.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !text.isEmpty else {
            throw TranscriptionError.emptyResult
        }

        return text
    }
}

