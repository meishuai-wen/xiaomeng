import AppKit
import XiaomengAppCore
import XiaomengAudio
import XiaomengCore
import XiaomengTranscription

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var hotkeyMonitor: GlobalHotkeyMonitor?
    private var streamingSession: StreamingDictationSession?
    private let textOutput = PasteboardTextOutput()
    private lazy var appController = AppController(
        audioRecorder: AudioRecorder(),
        transcriber: AppDelegate.makeTranscriberFromEnvironment(),
        textOutput: textOutput
    )

    func applicationDidFinishLaunching(_ notification: Notification) {
        AccessibilityPermission.requestIfNeeded()
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
        menu.addItem(NSMenuItem(title: "流式听写：\(streamingSession?.isRunning == true ? "运行中" : "待机")", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "快捷键：\(GlobalHotkey.toggleRecording.displayName)", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: recordingMenuTitle, action: #selector(toggleRecording), keyEquivalent: "r"))
        menu.addItem(NSMenuItem(title: "打开最近日志", action: #selector(openLatestMarkdownLog), keyEquivalent: "o"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "退出", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        return menu
    }

    private var recordingMenuTitle: String {
        if streamingSession?.isRunning == true {
            return "停止听写"
        }

        switch appController.recordingState {
        case .idle, .transcribing:
            "开始听写"
        case .toggleRecording, .pushToTalkRecording:
            "停止听写"
        }
    }

    @objc private func toggleRecording() {
        if streamingSession?.isRunning == true {
            streamingSession?.stop()
            streamingSession = nil
            statusItem?.menu = makeMenu()
            return
        }

        if let configuration = AppDelegate.makeStreamConfigurationFromEnvironment() {
            startStreamingDictation(configuration: configuration)
            return
        }

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

    private func startStreamingDictation(configuration: WhisperStreamConfiguration) {
        let session = StreamingDictationSession(configuration: configuration) { [weak self] text in
            do {
                try self?.textOutput.output(text)
            } catch {
                NSSound.beep()
            }
        }

        do {
            try session.start()
            streamingSession = session
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
        let homeDirectory = FileManager.default.homeDirectoryForCurrentUser.path
        let defaultExecutablePath = "/opt/homebrew/bin/whisper-cli"
        let defaultModelPath = "\(homeDirectory)/Models/whisper/ggml-small.bin"

        let executablePath = environment["XIAOMENG_WHISPER_CLI"] ?? defaultExecutablePath
        let modelPath = environment["XIAOMENG_WHISPER_MODEL"] ?? defaultModelPath

        guard
            FileManager.default.isExecutableFile(atPath: executablePath),
            FileManager.default.fileExists(atPath: modelPath)
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

    private static func makeStreamConfigurationFromEnvironment() -> WhisperStreamConfiguration? {
        let environment = ProcessInfo.processInfo.environment
        let homeDirectory = FileManager.default.homeDirectoryForCurrentUser.path
        let defaultExecutablePath = "/opt/homebrew/bin/whisper-stream"
        let defaultModelPath = "\(homeDirectory)/Models/whisper/ggml-small.bin"

        let executablePath = environment["XIAOMENG_WHISPER_STREAM"] ?? defaultExecutablePath
        let modelPath = environment["XIAOMENG_WHISPER_MODEL"] ?? defaultModelPath

        guard
            FileManager.default.isExecutableFile(atPath: executablePath),
            FileManager.default.fileExists(atPath: modelPath)
        else {
            return nil
        }

        return WhisperStreamConfiguration(
            executableURL: URL(fileURLWithPath: executablePath),
            modelURL: URL(fileURLWithPath: modelPath)
        )
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
