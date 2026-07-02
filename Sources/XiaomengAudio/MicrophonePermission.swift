import AVFoundation

public enum MicrophonePermission: Equatable, Sendable {
    case notDetermined
    case granted
    case denied
    case restricted

    public init(status: AVAuthorizationStatus) {
        switch status {
        case .authorized:
            self = .granted
        case .denied:
            self = .denied
        case .restricted:
            self = .restricted
        case .notDetermined:
            self = .notDetermined
        @unknown default:
            self = .denied
        }
    }
}
