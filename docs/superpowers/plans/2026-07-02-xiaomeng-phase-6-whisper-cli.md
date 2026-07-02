# 小梦第六阶段 whisper.cpp 命令行转写适配计划

> **给执行代理的要求：** 逐任务执行本计划。实现代码前先写测试，测试失败后再写最小实现。所有新增说明文档使用中文。

**目标：** 增加 whisper.cpp 命令行转写适配层，让 App 可以把录音文件交给本地 `whisper-cli` 和模型文件生成文本。

**架构：** 新增 `XiaomengTranscription` target，提供转写协议和 `WhisperCLITranscriber`。`XiaomengAppCore` 依赖转写协议，并提供 `transcribeLatestRecording` 入口，将真实转写结果写入 Markdown。

**技术栈：** Swift 6.0、Swift Package Manager、XCTest、Foundation、whisper.cpp CLI。

---

## 范围

本阶段包含：

- 新增 `XiaomengTranscription` target。
- 定义 `Transcribing` 协议。
- 实现 `WhisperCLIConfiguration`。
- 实现 `WhisperCLITranscriber` 的命令构建和输出解析。
- AppController 支持转写最近一次录音并写入 Markdown。

本阶段不包含：

- 自动下载 whisper.cpp。
- 自动下载模型。
- 设置页配置模型路径。
- 流式转写。
- Live2D 展示转写进度。

## 验证门禁

每次提交前运行：

```bash
swift test
swift build
git status --short
```

本机如果仍因 Command Line Tools 与 SDK 版本不匹配失败，以 GitHub Actions 的 macOS CI 结果作为完整验证依据，并在提交说明中明确本地阻塞原因。

