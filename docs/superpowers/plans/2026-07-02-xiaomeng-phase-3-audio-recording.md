# 小梦第三阶段音频录制实现计划

> **给执行代理的要求：** 逐任务执行本计划。实现代码前先写测试，测试失败后再写最小实现。所有新增说明文档使用中文。

**目标：** 新增独立的音频录制模块，封装麦克风权限、录音文件路径和 AVFoundation 录音实现，为后续全局快捷键触发真实录音做准备。

**架构：** 新增 `XiaomengAudio` library target，依赖 `XiaomengCore`，负责 AVFoundation 相关能力。`XiaomengCore` 继续只保存纯业务状态机，`XiaomengApp` 之后通过 `XiaomengAudio` 调用系统音频能力。

**技术栈：** Swift 6.0、Swift Package Manager、XCTest、Foundation、AVFoundation。

---

## 范围

本阶段包含：

- 新增 `XiaomengAudio` target。
- 定义麦克风权限状态映射。
- 定义录音配置与临时 WAV 文件路径生成。
- 实现基于 `AVAudioRecorder` 的录音器。
- 为纯逻辑部分补 XCTest。

本阶段不包含：

- 菜单栏按钮触发真实录音。
- 全局快捷键注册。
- whisper.cpp 转写。
- 自动粘贴。
- 首次启动权限引导 UI。

## 文件结构

- `Package.swift`：新增 `XiaomengAudio` library target 和测试 target。
- `Sources/XiaomengAudio/MicrophonePermission.swift`：麦克风权限状态与 AVFoundation 映射。
- `Sources/XiaomengAudio/AudioRecordingConfiguration.swift`：录音目录和文件路径生成。
- `Sources/XiaomengAudio/AudioRecorder.swift`：AVAudioRecorder 封装。
- `Tests/XiaomengAudioTests/MicrophonePermissionTests.swift`：权限状态映射测试。
- `Tests/XiaomengAudioTests/AudioRecordingConfigurationTests.swift`：录音文件路径测试。

## 任务 1：新增音频 target 和权限映射

**文件：**

- 修改：`Package.swift`
- 新建：`Sources/XiaomengAudio/MicrophonePermission.swift`
- 新建：`Tests/XiaomengAudioTests/MicrophonePermissionTests.swift`

- [ ] **步骤 1：写失败测试**

创建 `Tests/XiaomengAudioTests/MicrophonePermissionTests.swift`：

```swift
import AVFoundation
import XCTest
@testable import XiaomengAudio

final class MicrophonePermissionTests: XCTestCase {
    func testMapsAVAuthorizationStatusToAppPermission() {
        XCTAssertEqual(MicrophonePermission(status: .authorized), .granted)
        XCTAssertEqual(MicrophonePermission(status: .denied), .denied)
        XCTAssertEqual(MicrophonePermission(status: .restricted), .restricted)
        XCTAssertEqual(MicrophonePermission(status: .notDetermined), .notDetermined)
    }
}
```

- [ ] **步骤 2：运行测试确认失败**

运行：

```bash
swift test --filter MicrophonePermissionTests
```

期望：失败，因为 `XiaomengAudio` target 和 `MicrophonePermission` 尚未存在。

- [ ] **步骤 3：写最小实现**

修改 `Package.swift`，新增 product、target 和 test target：

```swift
.library(name: "XiaomengAudio", targets: ["XiaomengAudio"]),
```

```swift
.target(
    name: "XiaomengAudio",
    dependencies: ["XiaomengCore"]
),
.testTarget(
    name: "XiaomengAudioTests",
    dependencies: ["XiaomengAudio"]
),
```

创建 `Sources/XiaomengAudio/MicrophonePermission.swift`：

```swift
import AVFoundation

public enum MicrophonePermission: Equatable, Sendable {
    case notDetermined
    case granted
    case denied
    case restricted

    public init(status: AVAuthorizationStatus) {
        switch status {
        case .authorized:
            self = .granted
        case .denied:
            self = .denied
        case .restricted:
            self = .restricted
        case .notDetermined:
            self = .notDetermined
        @unknown default:
            self = .denied
        }
    }
}
```

- [ ] **步骤 4：运行测试**

运行：

```bash
swift test --filter MicrophonePermissionTests
```

期望：通过。

## 任务 2：录音文件路径生成

**文件：**

- 新建：`Sources/XiaomengAudio/AudioRecordingConfiguration.swift`
- 新建：`Tests/XiaomengAudioTests/AudioRecordingConfigurationTests.swift`

- [ ] **步骤 1：写失败测试**

创建 `Tests/XiaomengAudioTests/AudioRecordingConfigurationTests.swift`：

```swift
import Foundation
import XCTest
@testable import XiaomengAudio

final class AudioRecordingConfigurationTests: XCTestCase {
    func testCreatesWavURLInRecordingDirectory() {
        let directory = URL(fileURLWithPath: "/tmp/xiaomeng-recordings", isDirectory: true)
        let configuration = AudioRecordingConfiguration(recordingDirectory: directory)

        let url = configuration.makeRecordingURL(id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!)

        XCTAssertEqual(url.deletingLastPathComponent(), directory)
        XCTAssertEqual(url.lastPathComponent, "00000000-0000-0000-0000-000000000001.wav")
    }
}
```

- [ ] **步骤 2：运行测试确认失败**

运行：

```bash
swift test --filter AudioRecordingConfigurationTests
```

期望：失败，因为 `AudioRecordingConfiguration` 尚未存在。

- [ ] **步骤 3：写最小实现**

创建 `Sources/XiaomengAudio/AudioRecordingConfiguration.swift`：

```swift
import Foundation

public struct AudioRecordingConfiguration: Equatable, Sendable {
    public let recordingDirectory: URL

    public init(recordingDirectory: URL) {
        self.recordingDirectory = recordingDirectory
    }

    public static func temporary() -> AudioRecordingConfiguration {
        AudioRecordingConfiguration(
            recordingDirectory: FileManager.default.temporaryDirectory
                .appendingPathComponent("XiaomengRecordings", isDirectory: true)
        )
    }

    public func makeRecordingURL(id: UUID = UUID()) -> URL {
        recordingDirectory.appendingPathComponent(id.uuidString).appendingPathExtension("wav")
    }
}
```

- [ ] **步骤 4：运行测试**

运行：

```bash
swift test --filter AudioRecordingConfigurationTests
```

期望：通过。

## 任务 3：AVAudioRecorder 封装

**文件：**

- 新建：`Sources/XiaomengAudio/AudioRecorder.swift`

- [ ] **步骤 1：实现录音器接口**

创建 `Sources/XiaomengAudio/AudioRecorder.swift`：

```swift
import AVFoundation
import Foundation

public enum AudioRecorderError: Error, Equatable, Sendable {
    case alreadyRecording
    case notRecording
    case failedToStart
}

public final class AudioRecorder: NSObject, AVAudioRecorderDelegate {
    private let configuration: AudioRecordingConfiguration
    private let fileManager: FileManager
    private var recorder: AVAudioRecorder?
    private var currentURL: URL?

    public init(
        configuration: AudioRecordingConfiguration = .temporary(),
        fileManager: FileManager = .default
    ) {
        self.configuration = configuration
        self.fileManager = fileManager
    }

    public var isRecording: Bool {
        recorder?.isRecording == true
    }

    public func start(id: UUID = UUID()) throws -> URL {
        guard recorder == nil else {
            throw AudioRecorderError.alreadyRecording
        }

        try fileManager.createDirectory(at: configuration.recordingDirectory, withIntermediateDirectories: true)

        let url = configuration.makeRecordingURL(id: id)
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: 16_000,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsBigEndianKey: false
        ]

        let recorder = try AVAudioRecorder(url: url, settings: settings)
        recorder.delegate = self
        recorder.prepareToRecord()

        guard recorder.record() else {
            throw AudioRecorderError.failedToStart
        }

        self.recorder = recorder
        currentURL = url
        return url
    }

    public func stop() throws -> URL {
        guard let recorder, let currentURL else {
            throw AudioRecorderError.notRecording
        }

        recorder.stop()
        self.recorder = nil
        self.currentURL = nil
        return currentURL
    }
}
```

- [ ] **步骤 2：运行构建**

运行：

```bash
swift test
swift build
```

期望：通过。这个任务不直接在测试中启动真实麦克风录音，避免 CI 需要音频输入设备或权限弹窗。

## 验证门禁

每次提交前运行：

```bash
swift test
swift build
git status --short
```

本机如果仍因 Command Line Tools 与 SDK 版本不匹配失败，以 GitHub Actions 的 macOS CI 结果作为完整验证依据，并在提交说明中明确本地阻塞原因。

