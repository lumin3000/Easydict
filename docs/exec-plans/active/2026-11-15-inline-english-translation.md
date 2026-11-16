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

Translate Chinese in the focused input directly when `/en 中文\` is completed.
The official repository was cloned from tisfeng/Easydict at 30b53c9b7bb112f18aec9c5ce0ddfe808ee1cc66; the initial checkout was clean.

## 目标与范围

- 目标结果：Observe the terminating backslash, translate Chinese to English, replace only the command in place.
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
- [ ] Implement and add tests.
- [ ] Build/test and interaction verification.
- [ ] Review and final record.

## 验证

- Pending.

## 完成条件

- Relevant checks pass, or concrete environment blockers and missing coverage are recorded.
- Review has no unresolved actionable findings; history and local commit contain the complete implementation.
