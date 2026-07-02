# 小梦第二阶段录音会话核心实现计划

> **给执行代理的要求：** 逐任务执行本计划。每个步骤使用复选框（`- [ ]`）跟踪。实现代码前必须先写失败测试，再写最小实现。

**目标：** 为切换式录音和按住说话建立可测试的核心状态机，为后续接入全局快捷键、麦克风采集和 Live2D 状态事件提供稳定接口。

**架构：** 新增 `RecordingSessionController` 放在 `XiaomengCore` 中，只处理纯业务状态，不依赖 AppKit、Carbon 或 AVFoundation。控制器接收用户意图事件，输出录音动作和小梦助手事件，让系统 API 层后续只负责调用和执行。

**技术栈：** Swift 6.0、Swift Package Manager、XCTest。

---

## 范围

本阶段包含：

- 定义录音模式：切换式录音、按住说话。
- 定义录音会话状态：空闲、切换录音中、按住说话录音中、识别中。
- 定义录音动作输出：开始录音、停止录音、开始识别、忽略。
- 将录音会话事件映射为小梦助手事件。
- 补充 XCTest 覆盖核心状态流。

本阶段不包含：

- 注册真实全局快捷键。
- 调用麦克风录音 API。
- 调用 whisper.cpp。
- 自动粘贴。
- UI 设置页。

## 文件结构

- `Sources/XiaomengCore/RecordingSessionController.swift`：录音会话状态机。
- `Tests/XiaomengCoreTests/RecordingSessionControllerTests.swift`：录音会话状态机测试。

## 任务 1：切换式录音状态流

**文件：**

- 新建：`Sources/XiaomengCore/RecordingSessionController.swift`
- 新建：`Tests/XiaomengCoreTests/RecordingSessionControllerTests.swift`

- [ ] **步骤 1：写失败测试**

创建 `Tests/XiaomengCoreTests/RecordingSessionControllerTests.swift`：

```swift
import XCTest
@testable import XiaomengCore

final class RecordingSessionControllerTests: XCTestCase {
    func testToggleHotkeyStartsAndStopsRecording() {
        let controller = RecordingSessionController()

        let start = controller.handle(.toggleHotkeyPressed)
        XCTAssertEqual(start, RecordingSessionOutput(action: .startRecording(mode: .toggle), assistantEvent: .toggleRecordingStarted))
        XCTAssertEqual(controller.state, .toggleRecording)

        let stop = controller.handle(.toggleHotkeyPressed)
        XCTAssertEqual(stop, RecordingSessionOutput(action: .stopRecordingAndTranscribe, assistantEvent: .recordingStopped))
        XCTAssertEqual(controller.state, .transcribing)
    }
}
```

- [ ] **步骤 2：运行测试确认失败**

运行：

```bash
swift test --filter RecordingSessionControllerTests/testToggleHotkeyStartsAndStopsRecording
```

期望：失败，因为 `RecordingSessionController` 尚未存在。

- [ ] **步骤 3：写最小实现**

创建 `Sources/XiaomengCore/RecordingSessionController.swift`：

```swift
public enum RecordingMode: Equatable, Sendable {
    case toggle
    case pushToTalk
}

public enum RecordingSessionState: Equatable, Sendable {
    case idle
    case toggleRecording
    case pushToTalkRecording
    case transcribing
}

public enum RecordingSessionInput: Equatable, Sendable {
    case toggleHotkeyPressed
    case pushToTalkPressed
    case pushToTalkReleased
    case transcriptionFinished
    case transcriptionFailed
}

public enum RecordingSessionAction: Equatable, Sendable {
    case startRecording(mode: RecordingMode)
    case stopRecordingAndTranscribe
    case ignore
}

public struct RecordingSessionOutput: Equatable, Sendable {
    public let action: RecordingSessionAction
    public let assistantEvent: AssistantEvent?

    public init(action: RecordingSessionAction, assistantEvent: AssistantEvent?) {
        self.action = action
        self.assistantEvent = assistantEvent
    }
}

public final class RecordingSessionController {
    public private(set) var state: RecordingSessionState

    public init(initialState: RecordingSessionState = .idle) {
        self.state = initialState
    }

    public func handle(_ input: RecordingSessionInput) -> RecordingSessionOutput {
        switch (state, input) {
        case (.idle, .toggleHotkeyPressed):
            state = .toggleRecording
            return RecordingSessionOutput(action: .startRecording(mode: .toggle), assistantEvent: .toggleRecordingStarted)

        case (.toggleRecording, .toggleHotkeyPressed):
            state = .transcribing
            return RecordingSessionOutput(action: .stopRecordingAndTranscribe, assistantEvent: .recordingStopped)

        default:
            return RecordingSessionOutput(action: .ignore, assistantEvent: nil)
        }
    }
}
```

- [ ] **步骤 4：运行测试**

运行：

```bash
swift test --filter RecordingSessionControllerTests/testToggleHotkeyStartsAndStopsRecording
swift test
```

期望：通过。

## 任务 2：按住说话状态流

**文件：**

- 修改：`Sources/XiaomengCore/RecordingSessionController.swift`
- 修改：`Tests/XiaomengCoreTests/RecordingSessionControllerTests.swift`

- [ ] **步骤 1：写失败测试**

追加测试：

```swift
func testPushToTalkStartsOnPressAndStopsOnRelease() {
    let controller = RecordingSessionController()

    let start = controller.handle(.pushToTalkPressed)
    XCTAssertEqual(start, RecordingSessionOutput(action: .startRecording(mode: .pushToTalk), assistantEvent: .pushToTalkStarted))
    XCTAssertEqual(controller.state, .pushToTalkRecording)

    let stop = controller.handle(.pushToTalkReleased)
    XCTAssertEqual(stop, RecordingSessionOutput(action: .stopRecordingAndTranscribe, assistantEvent: .recordingStopped))
    XCTAssertEqual(controller.state, .transcribing)
}
```

- [ ] **步骤 2：运行测试确认失败**

运行：

```bash
swift test --filter RecordingSessionControllerTests/testPushToTalkStartsOnPressAndStopsOnRelease
```

期望：失败，因为按住说话事件尚未处理。

- [ ] **步骤 3：写最小实现**

在 `handle(_:)` 中补充分支：

```swift
case (.idle, .pushToTalkPressed):
    state = .pushToTalkRecording
    return RecordingSessionOutput(action: .startRecording(mode: .pushToTalk), assistantEvent: .pushToTalkStarted)

case (.pushToTalkRecording, .pushToTalkReleased):
    state = .transcribing
    return RecordingSessionOutput(action: .stopRecordingAndTranscribe, assistantEvent: .recordingStopped)
```

- [ ] **步骤 4：运行测试**

运行：

```bash
swift test --filter RecordingSessionControllerTests
swift test
```

期望：通过。

## 任务 3：识别完成和无效输入处理

**文件：**

- 修改：`Sources/XiaomengCore/RecordingSessionController.swift`
- 修改：`Tests/XiaomengCoreTests/RecordingSessionControllerTests.swift`

- [ ] **步骤 1：写失败测试**

追加测试：

```swift
func testTranscriptionFinishedReturnsToIdleWithSuccess() {
    let controller = RecordingSessionController(initialState: .transcribing)

    let output = controller.handle(.transcriptionFinished)

    XCTAssertEqual(output, RecordingSessionOutput(action: .ignore, assistantEvent: .transcriptionSucceeded))
    XCTAssertEqual(controller.state, .idle)
}

func testTranscriptionFailedReturnsToIdleWithError() {
    let controller = RecordingSessionController(initialState: .transcribing)

    let output = controller.handle(.transcriptionFailed)

    XCTAssertEqual(output, RecordingSessionOutput(action: .ignore, assistantEvent: .transcriptionEmpty))
    XCTAssertEqual(controller.state, .idle)
}

func testInvalidInputsAreIgnoredWithoutChangingState() {
    let controller = RecordingSessionController(initialState: .toggleRecording)

    let output = controller.handle(.pushToTalkPressed)

    XCTAssertEqual(output, RecordingSessionOutput(action: .ignore, assistantEvent: nil))
    XCTAssertEqual(controller.state, .toggleRecording)
}
```

- [ ] **步骤 2：运行测试确认失败**

运行：

```bash
swift test --filter RecordingSessionControllerTests
```

期望：失败，因为识别完成和失败事件尚未处理。

- [ ] **步骤 3：写最小实现**

在 `handle(_:)` 中补充分支：

```swift
case (.transcribing, .transcriptionFinished):
    state = .idle
    return RecordingSessionOutput(action: .ignore, assistantEvent: .transcriptionSucceeded)

case (.transcribing, .transcriptionFailed):
    state = .idle
    return RecordingSessionOutput(action: .ignore, assistantEvent: .transcriptionEmpty)
```

- [ ] **步骤 4：运行测试和构建**

运行：

```bash
swift test
swift build
```

期望：通过。

## 验证门禁

每次提交前运行：

```bash
swift test
swift build
git status --short
```

本机如果仍因 Command Line Tools 与 SDK 版本不匹配失败，以 GitHub Actions 的 macOS CI 结果作为完整验证依据，并在提交说明中明确本地阻塞原因。

