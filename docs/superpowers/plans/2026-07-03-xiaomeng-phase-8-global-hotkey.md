# 小梦第八阶段：全局快捷键实施计划

> **给自动化执行者：** 必须使用 `superpowers:executing-plans` 按任务执行。步骤使用 checkbox 跟踪。

**目标：** 让用户无需打开菜单，也能在任意输入场景用全局快捷键开始或停止录音。

**架构：** 在 `XiaomengAppCore` 中定义默认快捷键的产品语义和展示文案，便于测试和文档复用。macOS App 层使用 Carbon `RegisterEventHotKey` 注册 `Command+Shift+Space`，触发后复用现有 `toggleRecording()` 流程。

**技术栈：** Swift Package、XCTest、AppKit、Carbon HIToolbox。

---

### Task 1: 默认快捷键定义

**Files:**
- Create: `Sources/XiaomengAppCore/GlobalHotkey.swift`
- Test: `Tests/XiaomengAppCoreTests/GlobalHotkeyTests.swift`

- [x] **Step 1: 写失败测试**

验证默认切换录音快捷键展示为 `Command+Shift+Space`。

- [x] **Step 2: 运行测试确认失败**

Run: `swift test --filter GlobalHotkeyTests`

Expected: 本机 SwiftPM 可能因 Command Line Tools manifest 链接失败，远端 CI 负责最终验证。

- [x] **Step 3: 最小实现**

新增 `GlobalHotkey.toggleRecording` 及展示字段。

- [x] **Step 4: 运行测试确认通过**

Run: `swift test --filter GlobalHotkeyTests`

Expected: PASS，或本机环境失败但远端 CI PASS。

### Task 2: macOS 全局热键

**Files:**
- Create: `Sources/XiaomengApp/GlobalHotkeyMonitor.swift`
- Modify: `Sources/XiaomengApp/main.swift`
- Modify: `README.md`

- [x] **Step 1: 新增 Carbon 热键监听器**

注册 `Command+Shift+Space`，收到事件后回到主线程调用录音切换回调。

- [x] **Step 2: 接入 AppDelegate**

App 启动时创建并启动监听器，回调复用现有 `toggleRecording()`。

- [x] **Step 3: 更新中文 README**

说明全局快捷键和辅助功能权限。

- [x] **Step 4: 验证构建**

Run: `swift test && swift build`

Expected: PASS，或本机环境失败但远端 CI PASS。
