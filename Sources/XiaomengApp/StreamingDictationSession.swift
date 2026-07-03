import Foundation
import XiaomengTranscription

@MainActor
final class StreamingDictationSession: @unchecked Sendable {
    private let configuration: WhisperStreamConfiguration
    private let onText: @MainActor @Sendable (String) -> Void
    private var process: Process?
    private var outputPipe: Pipe?
    private var errorPipe: Pipe?
    private var outputBuffer = ""
    private var errorBuffer = ""
    private var filter = StreamingTranscriptFilter()

    init(
        configuration: WhisperStreamConfiguration,
        onText: @escaping @MainActor @Sendable (String) -> Void
    ) {
        self.configuration = configuration
        self.onText = onText
    }

    var isRunning: Bool {
        process?.isRunning == true
    }

    func start() throws {
        guard process == nil else {
            return
        }

        let process = Process()
        let outputPipe = Pipe()
        let errorPipe = Pipe()

        process.executableURL = configuration.executableURL
        process.arguments = configuration.arguments
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        outputPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty, let chunk = String(data: data, encoding: .utf8) else {
                return
            }

            Task { @MainActor [weak self] in
                self?.consume(chunk, source: .standardOutput)
            }
        }

        errorPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty, let chunk = String(data: data, encoding: .utf8) else {
                return
            }

            Task { @MainActor [weak self] in
                self?.consume(chunk, source: .standardError)
            }
        }

        process.terminationHandler = { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.clearProcessReferences()
            }
        }

        self.process = process
        self.outputPipe = outputPipe
        self.errorPipe = errorPipe
        try process.run()
    }

    func stop() {
        outputPipe?.fileHandleForReading.readabilityHandler = nil
        errorPipe?.fileHandleForReading.readabilityHandler = nil

        if process?.isRunning == true {
            process?.terminate()
        }

        clearProcessReferences()
    }

    private enum OutputSource {
        case standardOutput
        case standardError
    }

    private func consume(_ chunk: String, source: OutputSource) {
        switch source {
        case .standardOutput:
            outputBuffer += chunk
            consumeCompleteLines(from: &outputBuffer)
        case .standardError:
            errorBuffer += chunk
            consumeCompleteLines(from: &errorBuffer)
        }
    }

    private func consumeCompleteLines(from buffer: inout String) {
        while let newlineIndex = buffer.firstIndex(of: "\n") {
            let line = String(buffer[..<newlineIndex])
            buffer.removeSubrange(...newlineIndex)

            if let text = filter.nextText(from: line) {
                onText(text)
            }
        }
    }

    private func clearProcessReferences() {
        outputPipe?.fileHandleForReading.readabilityHandler = nil
        errorPipe?.fileHandleForReading.readabilityHandler = nil
        process = nil
        outputPipe = nil
        errorPipe = nil
    }
}
