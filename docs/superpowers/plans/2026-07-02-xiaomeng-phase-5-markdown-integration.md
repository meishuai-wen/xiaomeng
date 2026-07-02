# 小梦第五阶段 Markdown 写入集成计划

> **给执行代理的要求：** 逐任务执行本计划。实现代码前先写测试，测试失败后再写最小实现。所有新增说明文档使用中文。

**目标：** 将转写完成后的文本写入每日 Markdown 文件，并让 AppController 暴露最后写入的日志路径。

**架构：** 复用 `XiaomengCore.MarkdownLogStore`。`XiaomengAppCore.AppController` 在收到转写结果后负责写日志和更新小梦状态；真实 whisper.cpp 之后只需要把文本传入同一个入口。

**技术栈：** Swift 6.0、Swift Package Manager、XCTest、Foundation。

---

## 范围

本阶段包含：

- AppController 接收转写文本。
- 成功且非空文本追加到每日 Markdown。
- 暴露 `lastMarkdownURL`。
- 转写失败或空文本不写入日志。
- 菜单栏增加“打开今日日志”占位逻辑基础。

本阶段不包含：

- whisper.cpp 转写。
- 自动粘贴。
- 打开 Finder 或编辑器展示日志文件。
- UI 设置日志目录。

## 验证门禁

每次提交前运行：

```bash
swift test
swift build
git status --short
```

本机如果仍因 Command Line Tools 与 SDK 版本不匹配失败，以 GitHub Actions 的 macOS CI 结果作为完整验证依据，并在提交说明中明确本地阻塞原因。

