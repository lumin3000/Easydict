## 2026-11-16 | 任务：Use installed Apple translation models only

**Links:** [Completed plan](../../exec-plans/completed/2026-11/2026-11-16-local-only-translation.md)

### 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 26.6.2 / Xcode 26.0 (17A324)`

### 用户请求

Modify and install Easydict so translation uses local resources without online translation or AI services. The user explicitly approved a one-time official Apple Chinese/English offline-language download.

### 变更

- Added a native macOS 26 installed-language TranslationSession with downloads unavailable. Both inline `/en` and ordinary Apple Translate use this path. Missing/unsupported assets produce a localized error; inline text remains intact.
- Normalize auto-detected Chinese scripts using the existing local transform, since shared Chinese characters can be classified as Traditional even with Simplified assets installed.
- Enforce a fixed local-only provider allowlist: Apple Translate, Apple Dictionary and MDict. Preserve stored credentials while excluding online providers and CLI agents from normal query and settings paths.
- Use system language detection, OCR and speech; disable online alternatives, web-search shortcuts, telemetry, model refresh and updater startup/check controls. Explain the policy in General settings and lock Apple offline translation on.
- Handle excluded services safely at the storage boundary: the ordinary query window's legacy Youdao TTS lookup now returns nil instead of hitting an unsupported-provider Debug assertion.
- Added dedicated native-service and policy tests, removed the old online inline test, registered new files in Xcode and updated English/Chinese usage documentation.

### 设计意图

Use the framework's non-downloading initializer directly rather than the legacy Shortcut/fallback path. Keep the existing inline generation, focus, value and caret guards. Centralize provider availability and apply narrow guards to non-provider actions/background work; this custom build does not alter the system firewall or install a local LLM.

### 验证

- Final focused Debug `xcodebuild test`: **passed**, 12 tests in 3 suites, including parser/snapshot behavior, online factory/storage rejection, direct query/stream rejection and fixed local settings.
- `test-without-building -testPlan LocalEnvironment`, local translation suite: **passed**, 2 real tests. Installed Chinese-English model returned text containing hello/world; uninstalled French assets failed without downloading or fallback.
- Approved System Settings download installed only Simplified Mandarin and English (US). Native probe: installed, ready, canRequestDownloads=false. Translation requests never initiated downloads.
- Final installed app ordinary query: 明天见 → Apple Translate: See you tomorrow. Settings show forced offline translation and only local dictionary additions; update controls disabled.
- Final installed inline Chrome textarea: 😀 Prefix /en 明天见、 Suffix 🚀 → 😀 Prefix See you tomorrow Suffix 🚀; next insertion ! landed immediately after tomorrow. Single-line vertical-bar and contenteditable fullwidth-bar commands also translated successfully.
- User's malformed sentence translated literally to Test whether to apply toner for heat pollution. Local translation does not provide an AI rewriting/correction promise.
- Missing French assets retained the original command and logged the localized explanation. Continued editing during a long pending request retained the full command plus KEEP. Secure input remained seven masked characters.
- App PID/path and single-instance status verified after reinstall. Build/installed SHA256 manifests matched; no application Internet sockets were present at the observed check. This snapshot is not an OS-wide network-isolation claim.
- Review skill: updater beta-toggle and excluded-provider Debug assertion findings fixed, regression-tested and incrementally re-reviewed. No unresolved actionable findings; final source hashes and screenshots preserved outside Git and visually checked.
- `git diff --check`, project `plutil -lint` and String Catalog JSON validation passed. Xcode 26.0 compatibility overrides: signing disabled, Easydict-26 icon, Easydict-27.icon and unrelated CodexFormulaImageTests.swift excluded. Debug tests cover the build; full-suite, Release and distribution signing remain unvalidated.
- Installed the verified build in Applications and left it running at the user's request. Closed task-owned browser/Finder/Settings windows; prior installed versions backed up outside Applications.

### 受影响文件

- `Easydict/Swift/Service/Apple/LocalTranslationService.swift` and `AppleService.swift`
- `Easydict/Swift/Feature/Configuration/LocalOnlyPolicy.swift` and local settings
- Inline/action/shortcut integration, provider factory/storage/query/stream gates
- Detection, audio, startup/updater/analytics and settings views
- `Easydict/App/Localizable.xcstrings` and `Easydict.xcodeproj/project.pbxproj`
- Focused tests, bilingual inline documentation, this history and the completed plan

### 后续事项

- macOS 26 or later and installed source/target language packs are required. Other language packs must be installed explicitly by the user. Missing packs never trigger an online fallback.
- Full-suite and signed Release validation require a compatible toolchain and signing setup.
