import AppKit
import CoreGraphics
import XiaomengAppCore

final class PasteboardTextOutput: TextOutputting {
    private let pasteboard: NSPasteboard
    private let eventSource: CGEventSource?

    init(
        pasteboard: NSPasteboard = .general,
        eventSource: CGEventSource? = CGEventSource(stateID: .hidSystemState)
    ) {
        self.pasteboard = pasteboard
        self.eventSource = eventSource
    }

    func output(_ text: String) throws {
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        paste()
    }

    private func paste() {
        let keyCodeForV = CGKeyCode(9)
        let keyDown = CGEvent(keyboardEventSource: eventSource, virtualKey: keyCodeForV, keyDown: true)
        let keyUp = CGEvent(keyboardEventSource: eventSource, virtualKey: keyCodeForV, keyDown: false)

        keyDown?.flags = .maskCommand
        keyUp?.flags = .maskCommand
        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
    }
}
