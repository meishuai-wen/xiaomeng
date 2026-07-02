# Mac Speech-to-Markdown Live2D App Design

Date: 2026-07-02

## Goal

Build a macOS menu bar app that turns speech into text locally, appends every result to daily Markdown files, and can insert recognized text directly into the active input field. The app uses the character "Xiaomeng" as a Live2D assistant so the recording and transcription flow feels warm, visible, and less mechanical.

## Target Users

The first users are teammates who frequently write messages, notes, requirements, comments, and short documents on a Mac. They need fast speech input without sending audio to a cloud service. The app should feel useful during real work, not like a demo that requires constant attention.

## First-Version Scope

Included:

- macOS menu bar app.
- Local offline speech recognition.
- Chinese and English mixed dictation.
- Toggle recording hotkey: press once to start, press again to stop.
- Push-to-talk hotkey: hold to record, release to transcribe.
- Automatic daily Markdown log files.
- Optional automatic paste into the current cursor location.
- Menu bar controls for status, settings, today log, and model state.
- Live2D Xiaomeng floating assistant with state-based animations.

Excluded from the first version:

- Cloud speech recognition.
- Team sync or shared notes.
- Full meeting transcription workflow.
- Multi-character assistant system.
- Complex desktop pet behavior unrelated to speech input.
- Mobile or Windows support.

## Product Experience

The app runs quietly from the macOS menu bar. Users trigger dictation with global hotkeys instead of opening a full window.

For toggle recording, the first hotkey press starts recording and changes the assistant into a listening state. The second press stops recording, runs local transcription, writes the result into today's Markdown file, then optionally pastes the recognized text into the currently focused app.

For push-to-talk, holding the configured hotkey records audio and releasing it starts transcription. This is optimized for short commands, chat replies, and quick note snippets.

The floating Xiaomeng window can be shown, hidden, or pinned to a screen corner. It stays small enough to avoid covering work content. It reacts to app state, but text instructions and errors remain in native UI so accessibility and clarity do not depend on the character art.

## Recommended Technical Direction

Use Swift as the native macOS host app and use whisper.cpp for offline transcription.

Use WKWebView for the first Live2D integration. Swift owns system-level responsibilities: microphone capture, permissions, global hotkeys, transcription process orchestration, Markdown writes, clipboard insertion, settings, and menu bar UI. The WebView owns Live2D rendering and receives state events from Swift.

This keeps the core voice workflow native and reliable while isolating the character layer. If the Live2D layer has a rendering issue, the speech-to-text workflow can still function.

## Architecture

### Native App Layer

Responsibilities:

- Menu bar lifecycle.
- App settings and first-run onboarding.
- Microphone permission request and error handling.
- Audio recording.
- Global hotkey registration.
- Audio preprocessing into the format required by whisper.cpp.
- Local transcription job management.
- Markdown persistence.
- Clipboard and paste automation.
- Live2D state event dispatch.

Candidate modules:

- `AppShell`: menu bar app lifecycle and top-level dependency wiring.
- `HotkeyManager`: global hotkey registration and conflict handling.
- `AudioRecorder`: microphone capture and temporary audio file creation.
- `TranscriptionService`: whisper.cpp model loading and transcription execution.
- `MarkdownLogStore`: daily Markdown file creation and append operations.
- `TextInsertionService`: clipboard update and paste command dispatch.
- `AssistantStateController`: maps app events to Live2D states.
- `SettingsStore`: model path, log directory, hotkeys, paste behavior, assistant visibility.

### Live2D Assistant Layer

Responsibilities:

- Load Xiaomeng Live2D model assets.
- Play idle loop and state animations.
- React to high-level state changes from Swift.
- Track pointer position inside the floating assistant window.
- Provide click callbacks for simple commands such as opening the menu or toggling visibility.

The first version should use a small explicit message protocol from Swift to WebView:

```json
{
  "type": "assistantState",
  "state": "listening",
  "payload": {
    "volume": 0.42
  }
}
```

## Live2D State Machine

Required first-version states:

- `loadingModel`: Xiaomeng waits while the transcription model loads.
- `idle`: calm breathing, blinking, subtle hair and sleeve movement.
- `listening`: attentive listening pose for toggle recording.
- `pushToTalk`: more focused listening pose while the hotkey is held.
- `transcribing`: writing, thinking, or organizing notes.
- `success`: nodding or handing over a small note after text is inserted or saved.
- `error`: confused expression for recognition or save failures.
- `permission`: holding a small prompt card for microphone or accessibility permission.

State transition rules:

- App launch goes to `loadingModel`, then `idle`.
- Recording start goes to `listening` or `pushToTalk`.
- Recording stop goes to `transcribing`.
- Successful transcription goes to `success`, then returns to `idle`.
- Empty transcription goes to `error`, then returns to `idle`.
- Missing microphone or accessibility permission goes to `permission` until resolved.
- Model loading failure goes to `error` and exposes the native settings action.

Volume feedback:

- During recording, Swift sends normalized volume updates.
- Live2D uses volume only for subtle feedback, such as expression intensity or a small sound-wave accessory.
- Volume feedback must not cause large movement or distract from typing.

## Character Asset Direction

Use the provided Xiaomeng three-view image as the character reference. Preserve these core identity markers:

- Long pale yellow to cyan-green gradient hair.
- Side ponytail silhouette.
- Red and white Chinese-inspired outfit.
- Black boots.
- Warm, friendly anime expression.
- Sleeve and hem details inspired by the reference image.

First-version asset deliverables:

- One Live2D model based on the reference.
- Motion files for each required state.
- Expression variants for neutral, focused, happy, confused, and waiting.
- Small simplified app icon derived from the face or hair silhouette.
- Optional static fallback PNGs for cases where Live2D rendering is disabled.

The Live2D model should be friendly and work-focused rather than overly playful. It should support the voice workflow without making the app feel noisy in an office setting.

## Markdown Log Behavior

Default storage uses daily Markdown files in a user-configurable directory.

Suggested default path:

```text
~/Documents/SpeechNotes/YYYY-MM-DD.md
```

Append format:

```markdown
## HH:mm

Recognized text...
```

If the user records multiple snippets in quick succession, each snippet still gets a timestamp. The app should never overwrite existing notes. File write failures are surfaced through native UI and the assistant enters `error`.

## Text Insertion Behavior

The app supports optional automatic insertion into the active app after transcription succeeds.

Default behavior:

- Append to Markdown always.
- Paste into active app when the setting is enabled.
- Preserve the previous clipboard value when possible.

Text insertion depends on macOS accessibility permission. If permission is missing, transcription and Markdown logging still work, but paste automation is disabled and the assistant enters `permission`.

## Settings

First-version settings:

- Toggle recording hotkey.
- Push-to-talk hotkey.
- Enable or disable automatic paste.
- Markdown log directory.
- Whisper model path or model management status.
- Assistant window visibility.
- Assistant window size.
- Launch at login.

Settings should be reachable from the menu bar and from the assistant click menu.

## Error Handling

Required error cases:

- Microphone permission missing.
- Accessibility permission missing.
- Hotkey conflict.
- Transcription model missing.
- Model load failure.
- Recording failure.
- Empty or low-confidence transcription.
- Markdown write failure.
- Paste automation failure.
- Live2D asset load failure.

All critical errors must have native text feedback. The Live2D assistant provides emotional state feedback, but it is not the only place where errors are explained.

## Testing And Verification

Core verification:

- App launches as a menu bar app.
- Toggle recording starts and stops reliably.
- Push-to-talk starts on key down and stops on key up.
- Audio is transcribed locally without network access.
- Chinese and English mixed input is recognized.
- Text is appended to the correct daily Markdown file.
- Auto paste inserts text into common targets such as Notes, browser text areas, chat apps, and code editors.
- Existing clipboard content is restored when configured behavior requires it.
- Missing microphone permission blocks recording with clear guidance.
- Missing accessibility permission blocks paste only, not transcription or Markdown logging.
- Live2D state changes match app states.
- Live2D layer failure does not block speech recognition or Markdown logging.

Visual verification:

- Assistant window does not cover the menu bar or active input area by default.
- Idle animation is subtle enough for office use.
- Recording and transcribing states are clearly distinguishable.
- Error and permission states are visible without feeling alarming.
- The character remains recognizable from the provided reference.

## First-Version Defaults

Use these defaults unless the user changes them during implementation planning:

- Use a whisper.cpp model that balances Chinese-English quality and local speed on modern Apple Silicon. Start with a small or medium multilingual model during implementation benchmarking, then choose the smallest model that passes the mixed-language acceptance test.
- Do not bundle a large model directly into the app binary. Provide a first-run model setup flow and allow the user to choose a local model path.
- Default toggle hotkey: configurable during first-run setup, with a suggested value that avoids common macOS system shortcuts.
- Default push-to-talk hotkey: configurable during first-run setup, with a separate suggested value from the toggle hotkey.
- Automatic Markdown logging is enabled by default.
- Automatic paste is opt-in during first-run setup because it requires accessibility permission and affects the active app.
- Xiaomeng assistant is visible by default after first-run setup, with an easy menu bar toggle to hide it.
- The first Live2D model is a required first-version asset. Static PNG fallback is only for failure handling, not the primary experience.

## Acceptance Criteria

The first version is successful when a teammate can install the app, grant permissions, press a hotkey, speak a Chinese-English mixed sentence, see Xiaomeng react, find the sentence in today's Markdown file, and optionally have the same sentence inserted into the currently focused app.
