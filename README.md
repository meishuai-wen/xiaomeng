# 小梦

小梦是一个 macOS 菜单栏语音输入 App。当前分支已经具备最小端到端骨架：菜单栏启动、录音、通过本地 whisper.cpp 命令行转写、写入每日 Markdown。

## 当前能力

- 菜单栏常驻。
- 点击菜单中的“开始录音”开始录制。
- 再次点击“停止录音”结束录制。
- 如果配置了 whisper.cpp，会自动转写最近录音。
- 转写结果写入每日 Markdown：

```text
~/Documents/SpeechNotes/YYYY-MM-DD.md
```

- 菜单中“打开最近日志”可以打开最近写入的 Markdown 文件。

## 本地环境要求

需要完整 Xcode 或可用的 Command Line Tools。当前开发机如果遇到 SwiftPM manifest 链接错误，通常是 Command Line Tools 与 SDK 版本不匹配，需要切换到完整 Xcode：

```bash
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
```

验证：

```bash
swift test
swift build
```

## 配置 whisper.cpp

App 通过环境变量读取 whisper.cpp 命令行和模型路径：

```bash
export XIAOMENG_WHISPER_CLI=/path/to/whisper-cli
export XIAOMENG_WHISPER_MODEL=/path/to/ggml-model.bin
```

示例：

```bash
export XIAOMENG_WHISPER_CLI=/opt/homebrew/bin/whisper-cli
export XIAOMENG_WHISPER_MODEL=$HOME/Models/whisper/ggml-small.bin
```

## 启动

在当前功能分支工作区中运行：

```bash
cd /Users/mads/project/madsSecond/soud2text/.worktrees/phase-1-foundation
swift run XiaomengApp
```

启动后，macOS 菜单栏会出现“小梦”。

## 已知限制

- 还没有正式 `.app` 打包。
- 还没有全局快捷键。
- 还没有 Live2D 悬浮助手。
- 还没有自动粘贴到当前输入框。
- whisper.cpp 和模型路径暂时通过环境变量配置。

