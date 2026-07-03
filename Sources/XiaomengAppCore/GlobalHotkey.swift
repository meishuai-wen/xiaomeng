import Foundation

public enum GlobalHotkey: Equatable, Sendable {
    case toggleRecording

    public var displayName: String {
        switch self {
        case .toggleRecording:
            "Command+Shift+Space"
        }
    }

    public var actionTitle: String {
        switch self {
        case .toggleRecording:
            "开始或停止录音"
        }
    }
}
