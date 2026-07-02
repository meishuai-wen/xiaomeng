import AVFoundation
import Foundation

public enum AudioRecorderError: Error, Equatable, Sendable {
    case alreadyRecording
    case notRecording
    case failedToStart
}

public final class AudioRecorder: NSObject, AVAudioRecorderDelegate {
    private let configuration: AudioRecordingConfiguration
    private let fileManager: FileManager
    private var recorder: AVAudioRecorder?
    private var currentURL: URL?

    public init(
        configuration: AudioRecordingConfiguration = .temporary(),
        fileManager: FileManager = .default
    ) {
        self.configuration = configuration
        self.fileManager = fileManager
    }

    public var isRecording: Bool {
        recorder?.isRecording == true
    }

    public func start(id: UUID = UUID()) throws -> URL {
        guard recorder == nil else {
            throw AudioRecorderError.alreadyRecording
        }

        try fileManager.createDirectory(at: configuration.recordingDirectory, withIntermediateDirectories: true)

        let url = configuration.makeRecordingURL(id: id)
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: 16_000,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsBigEndianKey: false
        ]

        let recorder = try AVAudioRecorder(url: url, settings: settings)
        recorder.delegate = self
        recorder.prepareToRecord()

        guard recorder.record() else {
            throw AudioRecorderError.failedToStart
        }

        self.recorder = recorder
        currentURL = url
        return url
    }

    public func stop() throws -> URL {
        guard let recorder, let currentURL else {
            throw AudioRecorderError.notRecording
        }

        recorder.stop()
        self.recorder = nil
        self.currentURL = nil
        return currentURL
    }
}
