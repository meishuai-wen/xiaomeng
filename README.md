# 小梦

小梦是一个 macOS 菜单栏语音输入 App。当前分支已经具备最小端到端骨架：菜单栏启动、录音、通过本地 whisper.cpp 命令行转写、写入每日 Markdown。

## 当前能力

- 菜单栏常驻。
- 点击菜单中的“开始录音”开始录制。
- 再次点击“停止录音”结束录制。
- 在任意 App 中按 `Command+Shift+Space` 可以开始或停止录音。
- 如果配置了 whisper.cpp，会自动转写最近录音。
- 转写成功后会复制文本并模拟 `Command+V`，把文字粘贴到当前光标所在输入框。
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

## macOS 权限

首次使用需要允许麦克风权限。全局快捷键和自动粘贴需要开启辅助功能权限：

```text
系统设置 → 隐私与安全性 → 辅助功能 → 添加并启用当前运行的小梦进程或终端
```

如果是通过 `swift run XiaomengApp` 启动，通常需要给运行它的终端 App 授权。

## 配置 whisper.cpp

App 通过环境变量读取 whisper.cpp 命令行和模型路径：

```bash
export XIAOMENG_WHISPER_CLI=/path/to/whisper-cli
export XIAOMENG_WHISPER_MODEL=/path/to/ggml-model.bin
```

示例：

```bash
export XIAOMENG_WHISPER_CLI=/opt/homebrew/bin/whisper-cli
export XIAOMENG_WHISPER_MODEL=/Users/mads/Models/whisper/ggml-small.bin
```

如果本机还没有安装 whisper.cpp，可以先用 Homebrew 安装：

```bash
brew install whisper-cpp
```

当前机器已经安装好 `/opt/homebrew/bin/whisper-cli`，并下载了 `small` 模型到 `/Users/mads/Models/whisper/ggml-small.bin`。模型文件建议使用 `small` 或 `medium` 起步，中文和英文混合输入的准确率会比 `base` 更稳。

## 启动

### 方式一：本机 SwiftPM 运行

如果本机 SwiftPM 可用，在当前功能分支工作区中运行：

```bash
cd /Users/mads/project/madsSecond/soud2text/.worktrees/phase-1-foundation
export XIAOMENG_WHISPER_CLI=/opt/homebrew/bin/whisper-cli
export XIAOMENG_WHISPER_MODEL=/Users/mads/Models/whisper/ggml-small.bin
swift run XiaomengApp
```

启动后，macOS 菜单栏会出现“小梦”。

### 方式二：下载 CI 构建产物运行

当前机器的 Command Line Tools 存在 SwiftPM manifest 链接问题时，可以直接下载 GitHub Actions 构建好的 App：

```bash
mkdir -p /tmp/xiaomeng-app
gh run download --repo meishuai-wen/xiaomeng --name XiaomengApp-macos --dir /tmp/xiaomeng-app
ditto -x -k /tmp/xiaomeng-app/XiaomengApp-macos.zip /tmp/xiaomeng-app
open /tmp/xiaomeng-app/Xiaomeng.app
```

启动后，菜单栏会出现“小梦”。如果没有设置环境变量，App 会自动尝试使用 `/opt/homebrew/bin/whisper-cli` 和 `/Users/mads/Models/whisper/ggml-small.bin`。把光标放在任意输入框，按 `Command+Shift+Space` 开始录音，再按一次停止，转写结果会写入 Markdown 并自动粘贴。

## 已知限制

- 还没有正式 `.app` 打包。
- 还没有全局快捷键。
- 还没有 Live2D 悬浮助手。
- whisper.cpp 和模型路径暂时通过环境变量配置。
