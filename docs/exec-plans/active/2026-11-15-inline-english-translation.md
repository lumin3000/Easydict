# Inline English translation

- 状态：active
- 创建日期：2026-11-15
- 负责人：Codex
- 关联 Issue/PR：none

## 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 26.6.2 / Xcode 26.0 (17A324)`

## 背景

Translate Chinese in the focused input directly when `/en 中文、` or `/en 中文|` is completed. Keep the original backslash terminator compatible; the user requested Chinese-mode-friendly terminators during implementation.
The official repository was cloned from tisfeng/Easydict at 30b53c9b7bb112f18aec9c5ce0ddfe808ee1cc66; the initial checkout was clean.

## 目标与范围

- 目标结果：Observe `、`, `|`, or backslash, translate Chinese to English, replace only the command in place.
- 允许修改路径：EventMonitor integration, a focused InlineTranslation feature, associated tests, project references, task documentation.
- 同任务 history：`docs/histories/2026-11/2026-11-15-inline-english-translation.md`
- 用户限制：Implement inside Easydict; own the plan and tests. Work locally; no push or release.
- 非目标：General slash-command framework, unsupported input controls, terminal keystroke injection.
- 验收标准：Preserve surrounding text and clipboard; UTF-16-correct selection; no writes on translation failure, changed text, selection, or focus; existing translation provider; real build and focused tests plus interaction verification where permissions allow.

## 工作计划

1. Inspect event monitoring, translation providers and Accessibility replacement.
2. Implement command parsing and guarded AX replacement using the existing event monitor.
3. Add focused parser/state tests and a real translation service test.
4. Build/test, exercise the normal interaction, capture results, review, record and commit.

## 风险与决策

- AX text access and writable selected-text/range attributes are required; unsupported or secure inputs remain untouched.
- Collect the complete translation before replacing; streaming could destroy the command on partial failure.
- Subsequent typing/clicking cancels a pending operation; recheck focus, full value and caret before replacement because network latency overlaps normal editing.
- Reuse the configured translate-and-replace provider with an explicit English target.
- Keep implementation in one writer; no delegation is needed for this bounded feature.

## 进度

- [x] Inspect repository and platform integration.
- [x] Implement and add tests.
- [ ] Build/test and interaction verification.
- [x] Review and record the implementation; keep this plan active until interactive acceptance.

## 验证

- Package resolution passed. Initial test invocation required an unavailable provisioning profile; use `CODE_SIGNING_ALLOWED=NO` for local testing.
- The upstream default `Easydict-27.icon` fails in this host's Xcode 26.0 asset compiler (`The data couldn’t be read because it isn’t in the correct format`, icon export status 255). This occurs before feature compilation. Test with the repository's existing `Easydict-26.icon` using command-line asset selection/exclusion; preserve the shipped project icon settings.
- The application and feature sources compile with the icon override. The existing unrelated `CodexFormulaImageTests.swift` uses `Test.cancel`, unavailable in Xcode 26.0's Swift Testing. Exclude that file only from the local focused-test build; do not alter the upstream tests or claim full-suite validation.
- Scope/time checkpoint: implementation remains limited to command parsing, one AX controller and the existing monitor; initial dependency fetch/compilation and asset compatibility account for the extended validation time. Reuse the checkout-specific build products; do not expand into unrelated application refactoring.
- Focused Debug build/test passed: 7 unit tests, 26 input/boundary invocations. Real built-in translation test passed separately through `LocalEnvironment`, returning English containing `hello` and `world` in 2.233 seconds.
- Local test overrides: `CODE_SIGNING_ALLOWED=NO ASSETCATALOG_COMPILER_APPICON_NAME=Easydict-26 'EXCLUDED_SOURCE_FILE_NAMES=Easydict-27.icon CodexFormulaImageTests.swift'`. No repository signing, icon or unrelated-test changes were made.
- Interactive attempt used a local Chrome text area containing `😀 Prefix /en 明天见、`. The command remained intact; System Settings confirmed `Easydict-debug` Accessibility access was off. Permission confirmation was requested before changing this system access. End-to-end replacement is **not yet verified**. A screenshot was inspected and saved outside the repository.
- Review skill: no actionable findings in the 5-file source/project/test snapshot. Checked event wiring, strict command boundary, UTF-16 ranges, dedicated request instance, complete-result replacement, cancellation, focus/text/caret revalidation, secure/unsupported fields and unchanged clipboard. Snapshot hashes were rechecked after review.

## 完成条件

- Relevant checks pass, or concrete environment blockers and missing coverage are recorded.
- Review has no unresolved actionable findings; history and local commit contain the complete implementation.
