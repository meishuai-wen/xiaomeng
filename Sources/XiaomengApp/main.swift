import AppKit
import XiaomengAppCore
import XiaomengAudio
import XiaomengCore
import XiaomengTranscription

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var hotkeyMonitor: GlobalHotkeyMonitor?
    private let appController = AppController(
        audioRecorder: AudioRecorder(),
        transcriber: AppDelegate.makeTranscriberFromEnvironment(),
        textOutput: PasteboardTextOutput()
    )

    func applicationDidFinishLaunching(_ notification: Notification) {
        configureMenuBar()
        configureGlobalHotkey()
    }

    private func configureMenuBar() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.title = "小梦"
        item.menu = makeMenu()
        statusItem = item
    }

    private func configureGlobalHotkey() {
        let monitor = GlobalHotkeyMonitor { [weak self] in
            self?.toggleRecording()
        }
        monitor.start()
        hotkeyMonitor = monitor
    }

    private func makeMenu() -> NSMenu {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "状态：\(appController.assistantState.rawValue)", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "快捷键：\(GlobalHotkey.toggleRecording.displayName)", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: recordingMenuTitle, action: #selector(toggleRecording), keyEquivalent: "r"))
        menu.addItem(NSMenuItem(title: "打开最近日志", action: #selector(openLatestMarkdownLog), keyEquivalent: "o"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "退出", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        return menu
    }

    private var recordingMenuTitle: String {
        switch appController.recordingState {
        case .idle, .transcribing:
            "开始录音"
        case .toggleRecording, .pushToTalkRecording:
            "停止录音"
        }
    }

    @objc private func toggleRecording() {
        do {
            try appController.toggleRecording()
            if appController.recordingState == .transcribing {
                try appController.transcribeLatestRecording()
            }
        } catch {
            NSSound.beep()
        }

        statusItem?.menu = makeMenu()
    }

    @objc private func openLatestMarkdownLog() {
        guard let url = appController.lastMarkdownURL else {
            NSSound.beep()
            return
        }

        NSWorkspace.shared.open(url)
    }

    private static func makeTranscriberFromEnvironment() -> Transcribing? {
        let environment = ProcessInfo.processInfo.environment
        guard
            let executablePath = environment["XIAOMENG_WHISPER_CLI"],
            let modelPath = environment["XIAOMENG_WHISPER_MODEL"]
        else {
            return nil
        }

        return WhisperCLITranscriber(
            configuration: WhisperCLIConfiguration(
                executableURL: URL(fileURLWithPath: executablePath),
                modelURL: URL(fileURLWithPath: modelPath)
            )
        )
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
