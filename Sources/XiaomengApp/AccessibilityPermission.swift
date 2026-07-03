import ApplicationServices
import Foundation

enum AccessibilityPermission {
    static func requestIfNeeded() {
        let options = [
            kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true
        ] as CFDictionary

        AXIsProcessTrustedWithOptions(options)
    }
}
