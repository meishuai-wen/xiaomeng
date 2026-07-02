import Foundation

public protocol Transcribing {
    func transcribe(audioURL: URL) throws -> String
}

public enum TranscriptionError: Error, Equatable, Sendable {
    case emptyResult
    case commandFailed(status: Int32, output: String)
}

