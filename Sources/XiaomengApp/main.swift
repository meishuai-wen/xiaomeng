import AppKit
import XiaomengAppCore
import XiaomengAudio
import XiaomengCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private let appController = AppController(audioRecorder: AudioRecorder())

    func applicationDidFinishLaunching(_ notification: Notification) {
        configureMenuBar()
    }

    private func configureMenuBar() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.title = "小梦"
        item.menu = makeMenu()
        statusItem = item
    }

    private func makeMenu() -> NSMenu {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "状态：\(appController.assistantState.rawValue)", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: recordingMenuTitle, action: #selector(toggleRecording), keyEquivalent: "r"))
        menu.addItem(NSMenuItem(title: "打开今日日志（未接入）", action: nil, keyEquivalent: ""))
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
        } catch {
            NSSound.beep()
        }

        statusItem?.menu = makeMenu()
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
