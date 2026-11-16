## 2026-11-16 | 任务：Add inline English translation

**Links:** [Completed plan](../../exec-plans/completed/2026-11/2026-11-15-inline-english-translation.md)

### 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 26.6.2 / Xcode 26.0 (17A324)`

### 用户请求

Clone official Easydict locally and translate Chinese directly in the focused input. Support Chinese-input-friendly `、` or `|` endings; the user approved Accessibility access on 2026-11-16.

### 变更

- Added `/en 中文、`, `/en 中文|`, fullwidth `｜` and legacy backslash endings. AX focus/value/selection observation handles actual input changes, IME commits and paste.
- Added UTF-16 command parsing and exact range replacement, preserving surrounding text. A dedicated existing built-in provider request always targets English and completes before any write.
- Deduplicate notifications; cancel on edits, clicks, app changes and shutdown; recheck app, element, full value and caret before writing. Secure and unsupported inputs are excluded.
- Use an atomic full-value AX edit where supported. This fixes Chrome's selection-only behavior while preserving surrounding text. Position the caret after the AX text tree exposes the new value, fixing Chrome's return-to-start behavior. Native selected-text insertion remains available for read-only full values.
- Added focused tests, project references and bilingual usage documentation. No clipboard access or keystroke injection is used.

### 设计意图

Observe the content the user actually entered, reuse Easydict's service and monitor lifecycle, and commit a complete translation only to the unchanged original input. Live tests drove the browser write and caret fixes; no application-specific identifiers or generic command framework were introduced.

### 验证

- Final focused Debug `xcodebuild test`: **passed**, 7 tests / 28 invocations. Covers all endings, invalid/incomplete commands, multiline/traditional Chinese, UTF-16/emoji offsets, surrounding text, multiple commands and stale snapshots.
- Real built-in provider test through `LocalEnvironment`: **passed**, English contained `hello` and `world` (2.233 seconds). Interactive tests also called the actual provider.
- Final Chrome: textarea with `、`, single-line `|` and `｜`, and contenteditable with backslash. Expected results included `See you tomorrow`, `Thank you`, `Goodbye` and `Document: Good morning`. All passed.
- Prefix/suffix/caret: `😀 Prefix /en 明天见、 Suffix 🚀` became `😀 Prefix See you tomorrow Suffix 🚀`; next insertion produced `😀 Prefix See you tomorrow! Suffix 🚀`. Contenteditable similarly accepted `!` after `Good morning`.
- Pending edit cancellation retained the original long command plus ` KEEP`. Changing focus retained the original command while another input remained focused. A secure field retained its original nine masked characters. Passed.
- Final native TextEdit: `/en 晚安|` became `Good night`; the next insertion yielded `Good night!`. Passed. Test document saved outside the repository.
- Screenshots `accepted-prefix-suffix.png` and `accepted-native.png`, UI assertions, full logs and source hashes are preserved outside Git and were inspected. Task-owned windows and app instances were cleaned up.
- Review skill: no unresolved actionable findings after reviewing the final six-file source/project/test snapshot, including observer lifetime, stop behavior, cancellation and async caret completion. Source hashes unchanged after review. `git diff --check` and project `plutil -lint` passed.
- Xcode 26.0 local overrides: signing disabled, existing `Easydict-26` icon selected, `Easydict-27.icon` and unrelated `CodexFormulaImageTests.swift` excluded from this focused build. The upstream default icon and `Test.cancel` require a newer toolchain. No shipped settings or unrelated tests were edited; full-suite, Release and distribution signing remain unvalidated.
- Test setup correction: background CUA edits do not activate an app. Normal Finder opening activated the test app so Easydict observed the correct frontmost input. Initial permission-blocked results were not counted as successful interaction tests.

### 受影响文件

- `Easydict/Swift/Feature/ActionManager/InlineTranslationCommand.swift`
- `Easydict/Swift/Feature/ActionManager/InlineTranslationController.swift`
- `Easydict/Swift/Feature/ActionManager/FocusedInputObserver.swift`
- `Easydict/Swift/Utility/EventMonitor/Core/EventMonitor.swift`
- `EasydictTests/Feature/ActionManager/InlineTranslationCommandTests.swift`
- `Easydict.xcodeproj/project.pbxproj`
- `docs/user-docs/en/Inline-translation.md`
- `docs/user-docs/zh/Inline-translation.md`
- This history and the completed plan.

### 后续事项

- None for the requested local implementation. Full-suite and signed Release validation require a compatible toolchain and signing setup.
