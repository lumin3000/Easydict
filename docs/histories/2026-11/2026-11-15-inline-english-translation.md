## 2026-11-15 | 任务：Add inline English translation

**Links:** [Active plan](../../exec-plans/active/2026-11-15-inline-english-translation.md)

### 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 26.6.2 / Xcode 26.0 (17A324)`

### 用户请求

Clone the official Easydict repository and implement automatic Chinese-to-English replacement in the focused input. The user subsequently requested `、` or `|` terminators because backslash is inconvenient with Chinese input.

### 变更

- Added `/en 中文、` and `/en 中文|`, retaining backslash compatibility. Inspect committed input on terminator key-up or keyboard paste using the existing event monitor.
- Added strict command parsing, Chinese-content detection, multiline handling and UTF-16 replacement ranges, preserving surrounding text.
- Reuse the built-in Translate and Replace provider with an explicit English target and a dedicated service request. Wait for its complete successful result before making any text change.
- Cancel on typing, clicks, app switches and shutdown. Recheck focused app/element, entire text and caret before writing through AX selected-text APIs. Password fields and unsupported controls remain untouched; the clipboard is never used by the implementation.
- Added focused tests, project references and English/Chinese usage documentation.

### 设计意图

Reuse Easydict's existing event lifecycle and translation provider. Native AX replacement confines the write to the command, and complete-result validation avoids partial edits during network failures or normal editing.

### 验证

- Debug `xcodebuild test`, focused on `InlineTranslationCommandTests`: **passed**, 7 tests covering 26 invocations, including all terminators, incomplete/invalid input, multiline/traditional Chinese, emoji offsets, preservation of surrounding text, multiple commands and stale snapshots.
- `xcodebuild test-without-building -testPlan LocalEnvironment`, focused on `realTranslation()`: **passed**, actual built-in provider returned English containing `hello` and `world` in 2.233 seconds.
- Local environment overrides: signing disabled, existing `Easydict-26` icon selected and `Easydict-27.icon` excluded. Upstream `CodexFormulaImageTests.swift` was excluded from this focused build because Xcode 26.0 lacks `Test.cancel`. Default signing/icon settings and unrelated tests were not edited. Full-suite and Release validation were not performed.
- `git diff --check` and project `plutil -lint`: **passed**.
- Review skill: no actionable findings; the source/project/test content hashes were unchanged after review. The bounded implementation is sufficient for AX-writable text inputs without a generic command framework or synthetic keystroke replacement.
- Interactive Chrome attempt: `/en 明天见、` remained unchanged. System Settings showed `Easydict-debug` Accessibility permission **off**. The permission change requires user confirmation; actual replacement and Chinese IME composition remain **unverified**. The blocking screenshot was inspected and retained outside Git.

### 受影响文件

- `Easydict/Swift/Feature/ActionManager/InlineTranslationCommand.swift`
- `Easydict/Swift/Feature/ActionManager/InlineTranslationController.swift`
- `Easydict/Swift/Utility/EventMonitor/Core/EventMonitor.swift`
- `EasydictTests/Feature/ActionManager/InlineTranslationCommandTests.swift`
- `Easydict.xcodeproj/project.pbxproj`
- `docs/user-docs/en/Inline-translation.md`
- `docs/user-docs/zh/Inline-translation.md`
- This history and its active plan.

### 后续事项

- After Accessibility access is approved, relaunch this build and verify actual replacement for all terminators, surrounding-text preservation, continued-edit cancellation and password-field exclusion. Capture the final result, update this history and archive the plan only after acceptance.
