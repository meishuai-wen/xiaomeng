import Foundation
import XiaomengCore

@MainActor
public protocol AudioRecording: AnyObject {
    var isRecording: Bool { get }

    func start(mode: RecordingMode) throws -> URL
    func stop() throws -> URL
}
