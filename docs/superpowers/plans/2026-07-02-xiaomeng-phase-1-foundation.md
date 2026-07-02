# Xiaomeng Phase 1 Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the first verifiable foundation for Xiaomeng: a SwiftPM macOS/AppKit menu bar executable plus tested core modules for assistant state mapping and daily Markdown logging.

**Architecture:** Keep system UI in an executable target named `XiaomengApp` and reusable behavior in a library target named `XiaomengCore`. The first phase avoids whisper.cpp and Live2D SDK integration code; it creates stable interfaces and tests so those subsystems can be added safely in later phases.

**Tech Stack:** Swift 6.0, Swift Package Manager, XCTest, Foundation, AppKit.

---

## Scope

This plan implements the first independent slice only:

- Swift package structure.
- Core assistant state model.
- App-event to assistant-state mapping.
- Daily Markdown append logic.
- Minimal AppKit menu bar shell that compiles and can run with `swift run XiaomengApp`.

This plan does not implement:

- Actual microphone capture.
- whisper.cpp invocation.
- WKWebView Live2D rendering.
- Global hotkeys.
- Accessibility paste automation.
- Model download or first-run setup UI.

Those are separate phases after this foundation is green.

## File Structure

- `Package.swift`: SwiftPM manifest defining `XiaomengCore`, `XiaomengApp`, and `XiaomengCoreTests`.
- `Sources/XiaomengCore/AssistantState.swift`: assistant state enum and app event enum.
- `Sources/XiaomengCore/AssistantStateController.swift`: pure state transition logic.
- `Sources/XiaomengCore/MarkdownLogStore.swift`: daily Markdown file append behavior.
- `Sources/XiaomengApp/main.swift`: minimal AppKit menu bar app entrypoint.
- `Tests/XiaomengCoreTests/AssistantStateControllerTests.swift`: TDD coverage for state transitions.
- `Tests/XiaomengCoreTests/MarkdownLogStoreTests.swift`: TDD coverage for Markdown file creation and append format.

## Task 1: SwiftPM Skeleton

**Files:**

- Create: `Package.swift`
- Create: `Sources/XiaomengCore/AssistantState.swift`
- Create: `Sources/XiaomengApp/main.swift`
- Create: `Tests/XiaomengCoreTests/AssistantStateControllerTests.swift`

- [ ] **Step 1: Write the failing test**

Create `Tests/XiaomengCoreTests/AssistantStateControllerTests.swift`:

```swift
import XCTest
@testable import XiaomengCore

final class AssistantStateControllerTests: XCTestCase {
    func testInitialStateIsLoadingModel() {
        let controller = AssistantStateController()

        XCTAssertEqual(controller.currentState, .loadingModel)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```bash
swift test --filter AssistantStateControllerTests/testInitialStateIsLoadingModel
```

Expected: FAIL because `Package.swift` or `AssistantStateController` does not exist yet.

- [ ] **Step 3: Add minimal package and core types**

Create `Package.swift`:

```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Xiaomeng",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(name: "XiaomengCore", targets: ["XiaomengCore"]),
        .executable(name: "XiaomengApp", targets: ["XiaomengApp"])
    ],
    targets: [
        .target(name: "XiaomengCore"),
        .executableTarget(
            name: "XiaomengApp",
            dependencies: ["XiaomengCore"]
        ),
        .testTarget(
            name: "XiaomengCoreTests",
            dependencies: ["XiaomengCore"]
        )
    ]
)
```

Create `Sources/XiaomengCore/AssistantState.swift`:

```swift
public enum AssistantState: String, Equatable, Sendable {
    case loadingModel
    case idle
    case listening
    case pushToTalk
    case transcribing
    case success
    case error
    case permission
}

public final class AssistantStateController {
    public private(set) var currentState: AssistantState

    public init(initialState: AssistantState = .loadingModel) {
        self.currentState = initialState
    }
}
```

Create `Sources/XiaomengApp/main.swift`:

```swift
import AppKit
import XiaomengCore

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private let assistantStateController = AssistantStateController()

    func applicationDidFinishLaunching(_ notification: Notification) {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.title = "小梦"

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "状态：\(assistantStateController.currentState.rawValue)", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "退出", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        item.menu = menu

        statusItem = item
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
```

- [ ] **Step 4: Run tests and build**

Run:

```bash
swift test
swift build
```

Expected: both PASS.

- [ ] **Step 5: Commit**

```bash
git add Package.swift Sources Tests
git commit -m "feat(app): 初始化 Swift 菜单栏骨架" -m "- 添加 SwiftPM 包结构\n- 新增 XiaomengCore 和 XiaomengApp 目标\n- 添加助手初始状态测试"
```

## Task 2: Assistant State Transitions

**Files:**

- Modify: `Sources/XiaomengCore/AssistantState.swift`
- Create: `Sources/XiaomengCore/AssistantStateController.swift`
- Modify: `Tests/XiaomengCoreTests/AssistantStateControllerTests.swift`

- [ ] **Step 1: Write failing transition tests**

Replace `Tests/XiaomengCoreTests/AssistantStateControllerTests.swift`:

```swift
import XCTest
@testable import XiaomengCore

final class AssistantStateControllerTests: XCTestCase {
    func testInitialStateIsLoadingModel() {
        let controller = AssistantStateController()

        XCTAssertEqual(controller.currentState, .loadingModel)
    }

    func testModelLoadedMovesToIdle() {
        let controller = AssistantStateController()

        controller.handle(.modelLoaded)

        XCTAssertEqual(controller.currentState, .idle)
    }

    func testToggleRecordingMovesThroughListeningAndTranscribing() {
        let controller = AssistantStateController(initialState: .idle)

        controller.handle(.toggleRecordingStarted)
        XCTAssertEqual(controller.currentState, .listening)

        controller.handle(.recordingStopped)
        XCTAssertEqual(controller.currentState, .transcribing)
    }

    func testPushToTalkUsesDedicatedState() {
        let controller = AssistantStateController(initialState: .idle)

        controller.handle(.pushToTalkStarted)
        XCTAssertEqual(controller.currentState, .pushToTalk)
    }

    func testSuccessAndEmptyTranscriptionReturnToExpectedStates() {
        let controller = AssistantStateController(initialState: .transcribing)

        controller.handle(.transcriptionSucceeded)
        XCTAssertEqual(controller.currentState, .success)

        controller.handle(.returnToIdle)
        XCTAssertEqual(controller.currentState, .idle)

        controller.handle(.recordingStopped)
        controller.handle(.transcriptionEmpty)
        XCTAssertEqual(controller.currentState, .error)
    }

    func testPermissionMissingOverridesCurrentState() {
        let controller = AssistantStateController(initialState: .listening)

        controller.handle(.permissionMissing)

        XCTAssertEqual(controller.currentState, .permission)
    }
}
```

- [ ] **Step 2: Run tests to verify failure**

Run:

```bash
swift test --filter AssistantStateControllerTests
```

Expected: FAIL because `AssistantEvent` and `handle(_:)` do not exist.

- [ ] **Step 3: Implement minimal transition logic**

Replace `Sources/XiaomengCore/AssistantState.swift`:

```swift
public enum AssistantState: String, Equatable, Sendable {
    case loadingModel
    case idle
    case listening
    case pushToTalk
    case transcribing
    case success
    case error
    case permission
}

public enum AssistantEvent: Equatable, Sendable {
    case modelLoaded
    case toggleRecordingStarted
    case pushToTalkStarted
    case recordingStopped
    case transcriptionSucceeded
    case transcriptionEmpty
    case permissionMissing
    case modelLoadFailed
    case returnToIdle
}
```

Create `Sources/XiaomengCore/AssistantStateController.swift`:

```swift
public final class AssistantStateController {
    public private(set) var currentState: AssistantState

    public init(initialState: AssistantState = .loadingModel) {
        self.currentState = initialState
    }

    public func handle(_ event: AssistantEvent) {
        switch event {
        case .modelLoaded:
            currentState = .idle
        case .toggleRecordingStarted:
            currentState = .listening
        case .pushToTalkStarted:
            currentState = .pushToTalk
        case .recordingStopped:
            currentState = .transcribing
        case .transcriptionSucceeded:
            currentState = .success
        case .transcriptionEmpty, .modelLoadFailed:
            currentState = .error
        case .permissionMissing:
            currentState = .permission
        case .returnToIdle:
            currentState = .idle
        }
    }
}
```

- [ ] **Step 4: Run tests**

Run:

```bash
swift test --filter AssistantStateControllerTests
swift test
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add Sources/XiaomengCore Tests/XiaomengCoreTests/AssistantStateControllerTests.swift
git commit -m "feat(core): 添加助手状态机" -m "- 定义小梦状态和事件\n- 实现 App 事件到 Live2D 状态的映射\n- 补充状态转换测试"
```

## Task 3: Daily Markdown Log Store

**Files:**

- Create: `Sources/XiaomengCore/MarkdownLogStore.swift`
- Create: `Tests/XiaomengCoreTests/MarkdownLogStoreTests.swift`

- [ ] **Step 1: Write failing Markdown tests**

Create `Tests/XiaomengCoreTests/MarkdownLogStoreTests.swift`:

```swift
import Foundation
import XCTest
@testable import XiaomengCore

final class MarkdownLogStoreTests: XCTestCase {
    func testAppendCreatesDailyMarkdownFileWithTimestampHeading() throws {
        let directory = try makeTemporaryDirectory()
        let store = MarkdownLogStore(directory: directory)
        let date = try XCTUnwrap(makeDate(year: 2026, month: 7, day: 2, hour: 14, minute: 30))

        let fileURL = try store.append("你好 Xiaomeng", at: date)

        XCTAssertEqual(fileURL.lastPathComponent, "2026-07-02.md")
        let content = try String(contentsOf: fileURL, encoding: .utf8)
        XCTAssertEqual(content, "## 14:30\n\n你好 Xiaomeng\n\n")
    }

    func testAppendDoesNotOverwriteExistingContent() throws {
        let directory = try makeTemporaryDirectory()
        let store = MarkdownLogStore(directory: directory)
        let firstDate = try XCTUnwrap(makeDate(year: 2026, month: 7, day: 2, hour: 14, minute: 30))
        let secondDate = try XCTUnwrap(makeDate(year: 2026, month: 7, day: 2, hour: 14, minute: 32))

        let fileURL = try store.append("第一段", at: firstDate)
        _ = try store.append("second note", at: secondDate)

        let content = try String(contentsOf: fileURL, encoding: .utf8)
        XCTAssertEqual(content, "## 14:30\n\n第一段\n\n## 14:32\n\nsecond note\n\n")
    }

    private func makeTemporaryDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("xiaomeng-tests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private func makeDate(year: Int, month: Int, day: Int, hour: Int, minute: Int) -> Date? {
        var components = DateComponents()
        components.calendar = Calendar(identifier: .gregorian)
        components.timeZone = TimeZone(secondsFromGMT: 0)
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        return components.date
    }
}
```

- [ ] **Step 2: Run tests to verify failure**

Run:

```bash
swift test --filter MarkdownLogStoreTests
```

Expected: FAIL because `MarkdownLogStore` does not exist.

- [ ] **Step 3: Implement MarkdownLogStore**

Create `Sources/XiaomengCore/MarkdownLogStore.swift`:

```swift
import Foundation

public struct MarkdownLogStore: Sendable {
    private let directory: URL
    private let fileManager: FileManager
    private let calendar: Calendar

    public init(
        directory: URL,
        fileManager: FileManager = .default,
        calendar: Calendar = Calendar(identifier: .gregorian)
    ) {
        self.directory = directory
        self.fileManager = fileManager
        self.calendar = calendar
    }

    @discardableResult
    public func append(_ text: String, at date: Date = Date()) throws -> URL {
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        let fileURL = directory.appendingPathComponent(Self.dayFormatter.string(from: date) + ".md")
        let entry = "## \(Self.timeFormatter.string(from: date))\n\n\(text)\n\n"

        if fileManager.fileExists(atPath: fileURL.path) {
            let handle = try FileHandle(forWritingTo: fileURL)
            try handle.seekToEnd()
            if let data = entry.data(using: .utf8) {
                try handle.write(contentsOf: data)
            }
            try handle.close()
        } else {
            try entry.write(to: fileURL, atomically: true, encoding: .utf8)
        }

        return fileURL
    }

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
}
```

- [ ] **Step 4: Run tests**

Run:

```bash
swift test --filter MarkdownLogStoreTests
swift test
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add Sources/XiaomengCore/MarkdownLogStore.swift Tests/XiaomengCoreTests/MarkdownLogStoreTests.swift
git commit -m "feat(core): 添加每日 Markdown 记录" -m "- 实现按日期创建 Markdown 文件\n- 支持按时间戳追加识别结果\n- 补充文件创建和追加测试"
```

## Task 4: Menu Bar Shell Uses Core State

**Files:**

- Modify: `Sources/XiaomengApp/main.swift`

- [ ] **Step 1: Build current app**

Run:

```bash
swift build
```

Expected: PASS before editing.

- [ ] **Step 2: Replace menu shell**

Replace `Sources/XiaomengApp/main.swift`:

```swift
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
```

- [ ] **Step 3: Verify build**

Run:

```bash
swift build
swift test
```

Expected: PASS.

- [ ] **Step 4: Optional manual smoke run**

Run:

```bash
swift run XiaomengApp
```

Expected: menu bar item titled `小梦` appears. Stop it with Control-C from the terminal.

- [ ] **Step 5: Commit**

```bash
git add Sources/XiaomengApp/main.swift
git commit -m "feat(app): 接入菜单栏状态展示" -m "- App 启动后进入 idle 状态\n- 菜单栏展示当前助手状态\n- 保留后续录音和日志入口占位菜单项"
```

## Quality Gates

Run after each task:

```bash
swift test
swift build
git status --short
```

Expected:

- `swift test` passes.
- `swift build` passes.
- `git status --short` shows only intentional changes before commit and clean after commit.

## Self-Review

Spec coverage in this phase:

- Covers macOS menu bar app foundation.
- Covers assistant states and transition mapping for Live2D integration.
- Covers daily Markdown file creation and append behavior.
- Does not yet cover microphone capture, whisper.cpp, Live2D WKWebView rendering, hotkeys, permissions, or paste automation; those are intentionally deferred to later independent phases.

Placeholder scan:

- No `TBD`, `TODO`, `implement later`, or unspecified code steps are used.

Type consistency:

- `AssistantStateController`, `AssistantState`, `AssistantEvent`, and `MarkdownLogStore` names are consistent across tests and implementation steps.

