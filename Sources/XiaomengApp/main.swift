import AppKit
import XiaomengCore

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private let assistantStateController = AssistantStateController()

    func applicationDidFinishLaunching(_ notification: Notification) {
        assistantStateController.handle(.modelLoaded)
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
        menu.addItem(NSMenuItem(title: "状态：\(assistantStateController.currentState.rawValue)", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "开始录音（未接入）", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "打开今日日志（未接入）", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "退出", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        return menu
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
