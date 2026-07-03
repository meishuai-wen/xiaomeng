import ApplicationServices
import Foundation

enum AccessibilityPermission {
    static func requestIfNeeded() {
        let options = [
            "AXTrustedCheckOptionPrompt": true
        ] as CFDictionary

        AXIsProcessTrustedWithOptions(options)
    }
}
