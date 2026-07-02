import Foundation

public struct AudioRecordingConfiguration: Equatable, Sendable {
    public let recordingDirectory: URL

    public init(recordingDirectory: URL) {
        self.recordingDirectory = recordingDirectory
    }

    public static func temporary() -> AudioRecordingConfiguration {
        AudioRecordingConfiguration(
            recordingDirectory: FileManager.default.temporaryDirectory
                .appendingPathComponent("XiaomengRecordings", isDirectory: true)
        )
    }

    public func makeRecordingURL(id: UUID = UUID()) -> URL {
        recordingDirectory.appendingPathComponent(id.uuidString).appendingPathExtension("wav")
    }
}
