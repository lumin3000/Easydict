# Inline English translation

- 状态：completed
- 创建日期：2026-11-15
- 完成日期：2026-11-16
- 负责人：Codex
- 关联 Issue/PR：none

## 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 26.6.2 / Xcode 26.0 (17A324)`

## 背景

The user requested a local clone of official tisfeng/Easydict and in-place English translation of `/en 中文\`. During implementation they requested Chinese-input-friendly `、` or `|` endings. Initial checkout was clean at 30b53c9b7bb112f18aec9c5ce0ddfe808ee1cc66.

## 目标与范围

- 目标结果：Detect a completed command in the focused input and replace only its text with English. Support `、`, `|`, Chinese-mode fullwidth `｜`, and backslash.
- 允许修改路径：Focused input observation, inline translation controller/parser, EventMonitor lifecycle, related tests, project references and documentation.
- 同任务 history：`docs/histories/2026-11/2026-11-15-inline-english-translation.md`
- 用户限制：Implement inside Easydict; own planning and testing. Accessibility access approved on 2026-11-16. Local work only; no push or release.
- 非目标：Generic command framework, terminal injection, unsupported Accessibility controls.
- 验收标准：Complete real translation before writing; preserve surrounding text and clipboard; correct UTF-16 offsets and caret; cancel stale results after editing or focus changes; exclude secure inputs; build, focused tests, review and actual interaction verification.

## 工作计划

1. Inspect the repository, event lifecycle, translation service and Accessibility APIs.
2. Implement parsing, focused input observation and guarded replacement.
3. Run focused unit tests and the real translation provider.
4. Validate Chrome and native TextEdit, fix observed compatibility issues, capture screenshots, review and commit.

## 风险与决策

- Observe AX focus/value/selection notifications so IME commits and paste use the actual input value. Existing monitor events cancel work on typing/clicking. Stop prevents app activation from restarting observation.
- Deduplicate value/selection notifications for an outstanding request. Check the same app, element, full text and caret before replacement.
- Reuse the built-in Translate and Replace provider in a dedicated request with explicit English target. No text is removed before a complete successful result.
- Prefer an atomic AXValue edit when writable; compute the full value by replacing exactly the parsed UTF-16 range. Use native selected-text insertion where the full value is read-only.
- Chrome exposed selection-only writes and an asynchronous caret issue during live testing. Finish caret positioning after the expected new value becomes observable.
- CUA edits background windows without making them the system frontmost app. Normal Finder application opening was required for a valid focused-input test; this was an automation activation issue, not a denied keyboard permission.
- No clipboard access, app-name special cases, test hooks or synthetic keystroke replacement. One implementation writer; no delegation was needed.

## 进度

- [x] Clone and inspect the repository.
- [x] Implement and add tests.
- [x] Build, real-service and interactive validation.
- [x] Review, evidence, history and local delivery.

## 验证

- Final Debug `xcodebuild test`, focused on `InlineTranslationCommandTests`: **passed**, 7 tests and 28 input/boundary invocations.
- Real provider `realTranslation()` under `LocalEnvironment`: **passed**, actual English contained `hello` and `world`; final UI tests also used actual translation responses.
- Local Xcode 26.0 overrides: `CODE_SIGNING_ALLOWED=NO ASSETCATALOG_COMPILER_APPICON_NAME=Easydict-26 'EXCLUDED_SOURCE_FILE_NAMES=Easydict-27.icon CodexFormulaImageTests.swift'`. Upstream default icon format and unrelated `Test.cancel` usage require a newer Xcode. Shipped settings and unrelated tests were not changed. Full-suite, Release and distribution signing were not validated.
- Chrome: all four terminators; textarea, single-line and contenteditable inputs; prefix/suffix/emoji preservation; append-after-translation caret; pending-edit and focus cancellation; secure-field exclusion. **Passed**.
- Final TextEdit: `/en 晚安|` became `Good night`; appending `!` produced `Good night!`. **Passed**.
- Final Chrome screenshot: `😀 Prefix /en 明天见、 Suffix 🚀` became `😀 Prefix See you tomorrow Suffix 🚀`; appending `!` at the returned caret produced `😀 Prefix See you tomorrow! Suffix 🚀`.
- Screenshots, native sample, UI assertions, full test logs and final source hashes are preserved outside Git. Test windows and task-owned application instances were cleaned up.
- Review: examined parser, observer ownership, lifecycle, deduplication, request cancellation, guarded writes and caret completion; no unresolved actionable findings. Source hashes rechecked. `git diff --check` and project `plutil -lint` passed.
- Scope/time checkpoint: validation time included initial dependency compilation, Xcode compatibility and actual browser write/caret defects. Reused checkout-specific build products and kept fixes inside the feature.

## 完成条件

- [x] Supported input cases pass actual UI verification and relevant tests.
- [x] No unresolved actionable review findings; history and local commits contain the implementation.
