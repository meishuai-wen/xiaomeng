import Carbon.HIToolbox
import Foundation

final class GlobalHotkeyMonitor {
    private enum HotkeyID {
        static let toggleRecording = UInt32(1)
    }

    private let onToggleRecording: @MainActor () -> Void
    private var eventHandler: EventHandlerRef?
    private var toggleRecordingHotkey: EventHotKeyRef?

    init(onToggleRecording: @escaping @MainActor () -> Void) {
        self.onToggleRecording = onToggleRecording
    }

    deinit {
        stop()
    }

    func start() {
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        InstallEventHandler(
            GetApplicationEventTarget(),
            GlobalHotkeyMonitor.handleHotkeyEvent,
            1,
            &eventType,
            Unmanaged.passUnretained(self).toOpaque(),
            &eventHandler
        )

        var hotkeyID = EventHotKeyID(
            signature: GlobalHotkeyMonitor.fourCharacterCode("XMHK"),
            id: HotkeyID.toggleRecording
        )

        RegisterEventHotKey(
            UInt32(kVK_Space),
            UInt32(cmdKey | shiftKey),
            hotkeyID,
            GetApplicationEventTarget(),
            0,
            &toggleRecordingHotkey
        )
    }

    func stop() {
        if let toggleRecordingHotkey {
            UnregisterEventHotKey(toggleRecordingHotkey)
            self.toggleRecordingHotkey = nil
        }

        if let eventHandler {
            RemoveEventHandler(eventHandler)
            self.eventHandler = nil
        }
    }

    @MainActor
    private func triggerToggleRecording() {
        onToggleRecording()
    }

    private static let handleHotkeyEvent: EventHandlerUPP = { _, event, userData in
        guard let event, let userData else {
            return OSStatus(eventNotHandledErr)
        }

        var hotkeyID = EventHotKeyID()
        let status = GetEventParameter(
            event,
            EventParamName(kEventParamDirectObject),
            EventParamType(typeEventHotKeyID),
            nil,
            MemoryLayout<EventHotKeyID>.size,
            nil,
            &hotkeyID
        )

        guard status == noErr, hotkeyID.id == HotkeyID.toggleRecording else {
            return OSStatus(eventNotHandledErr)
        }

        let monitor = Unmanaged<GlobalHotkeyMonitor>
            .fromOpaque(userData)
            .takeUnretainedValue()

        Task { @MainActor in
            monitor.triggerToggleRecording()
        }

        return noErr
    }

    private static func fourCharacterCode(_ string: String) -> OSType {
        string.utf8.reduce(0) { result, character in
            (result << 8) + OSType(character)
        }
    }
}
