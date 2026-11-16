# Local-only translation

- 状态：active
- 创建日期：2026-11-16
- 负责人：Codex
- 关联 Issue/PR：none

## 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 26.6.2 / Xcode 26.0 (17A324)`

## 背景

The user explicitly requires local translation with no online services and authorizes code changes. The installed inline implementation currently uses built-in online AI. Baseline b3bdfaf is clean; the old app was stopped before further work.

## 目标与范围

- 目标结果：Inline and ordinary translation use installed Apple language assets only; preserve input and show a localized explanation when unavailable. Disable online translation providers, detection/OCR/TTS alternatives and background service/update/telemetry entry points in this custom build.
- 允许修改路径：Apple/local translation service, inline/action integration, service registry/storage, configuration/startup, detection/audio/background entry points, tests, project references and documentation.
- 同任务 history：`docs/histories/2026-11/2026-11-16-local-only-translation.md`
- 用户限制：No online translation or AI requests. User separately approved one-time official Apple Chinese/English language-asset downloads. Do not run previous online provider tests. Preserve clipboard, surrounding text, caret and cancellation behavior; reinstall and launch the resulting app.
- 非目标：Local LLM installation, cloud fallback, OS-wide firewall/network changes, unrelated upstream refactoring.
- 验收标准：Non-downloading TranslationSession; actual offline translation when assets are installed; missing/unsupported assets fail without changing input; online services inaccessible through normal app service/action paths; focused tests, review and UI validation pass.

## 工作计划

1. Inspect local framework contracts, assets and app service/background entry points.
2. Implement installed-assets-only translation and local-only service policy.
3. Download only the approved Apple language assets; run local tests and validate failures.
4. Review, document, build, reinstall and launch the tested application.

## 风险与决策

- SDK evidence: macOS 26 offers `TranslationSession(installedSource:target:)`; probe reports `canRequestDownloads=false`. Current Chinese/English assets are supported but not installed, so `isReady=false`.
- Use that native session directly, bypassing the legacy SwiftUI/Shortcut fallback and avoiding any automatic asset download from a translation request. Earlier macOS versions fail clearly.
- Local-only policy is fixed for this custom build; stored online credentials are retained but providers are unavailable. Normalize existing settings to local choices before startup work.
- Keep changes in one writer. Reuse the established checkout-specific build products and local Xcode compatibility overrides; no online model validation.

## 进度

- [x] Inspect SDK, language assets and service entry points.
- [ ] Implement local translation and policy.
- [ ] Assets, tests and actual UI verification.
- [ ] Review, history, install and launch.

## 验证

- Read-only native probe: Chinese/English status `supported`, `canRequestDownloads=false`, `isReady=false`. No translation or download was requested.
- Pending implementation checks.

## 完成条件

- Required local checks pass and any remaining asset/environment limitation is explicit.
- No unresolved actionable review findings; local commit, history and installed application reflect the tested code.
