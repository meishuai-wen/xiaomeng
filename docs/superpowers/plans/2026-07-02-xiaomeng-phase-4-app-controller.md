# 小梦第四阶段菜单栏录音协调实现计划

> **给执行代理的要求：** 逐任务执行本计划。实现代码前先写测试，测试失败后再写最小实现。所有新增说明文档使用中文。

**目标：** 将菜单栏 App 与录音会话、音频录制模块连接起来，让“开始录音/停止录音”的应用层流程具备可测试实现。

**架构：** 新增 `XiaomengAppCore` library target，依赖 `XiaomengCore` 和 `XiaomengAudio`。`XiaomengAppCore` 放置 `AppController`，负责接收 UI 事件、驱动录音会话状态机、调用录音服务、更新小梦状态。`XiaomengApp` 只保留 AppKit 菜单栏展示和点击动作。

**技术栈：** Swift 6.0、Swift Package Manager、XCTest、Foundation、AppKit、AVFoundation。

---

## 范围

本阶段包含：

- 在 `XiaomengAudio` 中定义录音服务协议。
- 让 `AudioRecorder` 实现该协议。
- 新增 `XiaomengAppCore` target。
- 新增 `AppController`，协调录音会话、录音服务和小梦状态。
- 菜单栏“开始录音/停止录音”调用 `AppController`。
- 为 `AppController` 添加测试。

本阶段不包含：

- 全局快捷键注册。
- 麦克风权限弹窗引导。
- whisper.cpp 转写。
- Live2D WebView 渲染。
- 自动粘贴。

## 文件结构

- `Package.swift`：新增 `XiaomengAppCore` target 和测试 target，并让 `XiaomengApp` 依赖它。
- `Sources/XiaomengAudio/AudioRecording.swift`：录音服务协议。
- `Sources/XiaomengAudio/AudioRecorder.swift`：实现录音协议。
- `Sources/XiaomengAppCore/AppController.swift`：应用协调器。
- `Tests/XiaomengAppCoreTests/AppControllerTests.swift`：应用协调器测试。
- `Sources/XiaomengApp/main.swift`：菜单栏调用应用协调器。

## 验证门禁

每次提交前运行：

```bash
swift test
swift build
git status --short
```

本机如果仍因 Command Line Tools 与 SDK 版本不匹配失败，以 GitHub Actions 的 macOS CI 结果作为完整验证依据，并在提交说明中明确本地阻塞原因。

