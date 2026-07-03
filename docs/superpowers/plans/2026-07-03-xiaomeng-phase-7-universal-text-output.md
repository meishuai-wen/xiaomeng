# 小梦第七阶段：通用文本输出实施计划

> **给自动化执行者：** 必须使用 `superpowers:executing-plans` 按任务执行。步骤使用 checkbox 跟踪。

**目标：** 让本地转写成功后的文字既写入 Markdown，又能自动送到当前光标所在输入框。

**架构：** 在 `XiaomengAppCore` 中新增可测试的 `TextOutputting` 接口，`AppController` 在完成非空转写后调用它。macOS 具体实现放在 `XiaomengApp`，通过剪贴板写入文本并模拟 Command+V，保持核心模块不依赖 AppKit。

**技术栈：** Swift Package、XCTest、AppKit、CoreGraphics。

---

### Task 1: 核心输出接口

**Files:**
- Create: `Sources/XiaomengAppCore/TextOutputting.swift`
- Modify: `Sources/XiaomengAppCore/AppController.swift`
- Test: `Tests/XiaomengAppCoreTests/AppControllerTests.swift`

- [x] **Step 1: 写失败测试**

在 `Tests/XiaomengAppCoreTests/AppControllerTests.swift` 增加：

```swift
func testCompletedTranscriptionOutputsTrimmedText() throws {
    let directory = try makeTemporaryDirectory()
    let recorder = FakeAudioRecorder()
    let textOutput = FakeTextOutput()
    let controller = AppController(
        audioRecorder: recorder,
        textOutput: textOutput,
        markdownLogStore: MarkdownLogStore(directory: directory)
    )

    try controller.completeTranscription(text: "  你好 Xiaomeng  ", at: Date())

    XCTAssertEqual(textOutput.outputTexts, ["你好 Xiaomeng"])
    XCTAssertEqual(controller.assistantState, .success)
}

func testEmptyTranscriptionDoesNotOutputText() throws {
    let directory = try makeTemporaryDirectory()
    let recorder = FakeAudioRecorder()
    let textOutput = FakeTextOutput()
    let controller = AppController(
        audioRecorder: recorder,
        textOutput: textOutput,
        markdownLogStore: MarkdownLogStore(directory: directory)
    )

    try controller.completeTranscription(text: "   ", at: Date())

    XCTAssertTrue(textOutput.outputTexts.isEmpty)
    XCTAssertEqual(controller.assistantState, .error)
}
```

并增加测试替身：

```swift
private final class FakeTextOutput: TextOutputting {
    private(set) var outputTexts: [String] = []

    func output(_ text: String) throws {
        outputTexts.append(text)
    }
}
```

- [x] **Step 2: 运行测试确认失败**

Run: `swift test --filter XiaomengAppCoreTests`

Expected: 当前本机 SwiftPM 可能因 Command Line Tools manifest 链接问题失败；如果是环境失败，保留失败输出并用 GitHub Actions 验证。

- [x] **Step 3: 最小实现**

新增 `TextOutputting`：

```swift
import Foundation

public protocol TextOutputting {
    func output(_ text: String) throws
}

public struct NoOpTextOutput: TextOutputting {
    public init() {}

    public func output(_ text: String) throws {}
}
```

在 `AppController` 注入 `textOutput`，并在写入 Markdown 后调用 `try textOutput.output(trimmedText)`。

- [x] **Step 4: 运行测试确认通过**

Run: `swift test --filter XiaomengAppCoreTests`

Expected: PASS，或本机环境失败但远端 CI PASS。

- [x] **Step 5: 提交**

```bash
git add Sources/XiaomengAppCore Tests/XiaomengAppCoreTests docs/superpowers/plans/2026-07-03-xiaomeng-phase-7-universal-text-output.md
git commit -m "feat(app-core): 添加转写文本输出接口"
```

### Task 2: macOS 剪贴板粘贴实现

**Files:**
- Create: `Sources/XiaomengApp/PasteboardTextOutput.swift`
- Modify: `Sources/XiaomengApp/main.swift`
- Modify: `README.md`

- [x] **Step 1: 新增 macOS 输出实现**

创建 `PasteboardTextOutput`，负责写入 `NSPasteboard.general` 并通过 `CGEvent` 发送 Command+V。

- [x] **Step 2: 接入 App 启动**

在 `AppDelegate` 创建 `AppController` 时传入 `PasteboardTextOutput()`。

- [x] **Step 3: 更新中文 README**

说明当前自动粘贴依赖“辅助功能”权限：系统设置 → 隐私与安全性 → 辅助功能。

- [x] **Step 4: 验证构建**

Run: `swift build`

Expected: PASS，或本机环境失败但远端 CI PASS。

- [x] **Step 5: 提交**

```bash
git add Sources/XiaomengApp README.md docs/superpowers/plans/2026-07-03-xiaomeng-phase-7-universal-text-output.md
git commit -m "feat(app): 支持转写后自动粘贴"
```
