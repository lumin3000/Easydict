//
//  LocalTranslationService.swift
//  Easydict
//
//  Copyright © 2026 izual. All rights reserved.
//

import Foundation
import NaturalLanguage
import Translation

// MARK: - LocalTranslationService

/// Uses installed Apple models only; never opens download UI or invokes a cloud/Shortcut fallback.
struct LocalTranslationService {
    @MainActor
    func translate(_ text: String, from: Language, to: Language) async throws -> String {
        guard #available(macOS 26.0, *) else { throw LocalTranslationError.requiresMacOS26 }
        try Task.checkCancellation()
        guard to != .auto else { throw LocalTranslationError.unsupportedPair }

        let source: Locale.Language
        if from == .auto {
            guard let detected = NLLanguageRecognizer.dominantLanguage(for: text) else {
                throw LocalTranslationError.undetectedLanguage
            }
            // Short Chinese strings with shared characters are often classified as Traditional.
            // Reuse the app's script check so e.g. “你好，世界！” uses the installed Simplified model.
            if detected == .simplifiedChinese || detected == .traditionalChinese {
                source = Locale.Language(identifier: text == text.toSimplifiedChinese() ? "zh-Hans" : "zh-Hant")
            } else {
                source = Locale.Language(identifier: detected.rawValue)
            }
        } else {
            source = Locale.Language(identifier: AppleLanguageMapper.shared.languageCode(for: from))
        }
        let target = Locale.Language(identifier: AppleLanguageMapper.shared.languageCode(for: to))
        if source == target { return text }

        switch await LanguageAvailability().status(from: source, to: target) {
        case .installed:
            break
        case .supported:
            throw LocalTranslationError.languagesMissing
        case .unsupported:
            throw LocalTranslationError.unsupportedPair
        @unknown default:
            throw LocalTranslationError.languagesMissing
        }

        let session = TranslationSession(installedSource: source, target: target)
        guard !session.canRequestDownloads, await session.isReady else {
            throw LocalTranslationError.languagesMissing
        }
        return try await withTaskCancellationHandler {
            let response = try await session.translate(text)
            try Task.checkCancellation()
            return response.targetText
        } onCancel: {
            Task { @MainActor in session.cancel() }
        }
    }
}

// MARK: - LocalTranslationError

enum LocalTranslationError: Error, LocalizedError, Equatable {
    case languagesMissing
    case unsupportedPair
    case requiresMacOS26
    case undetectedLanguage
    case onlineServicesDisabled

    // MARK: Internal

    var errorDescription: String? {
        switch self {
        case .languagesMissing:
            String(localized: "offline.translation.languages_missing")
        case .unsupportedPair:
            String(localized: "offline.translation.unsupported_pair")
        case .requiresMacOS26:
            String(localized: "offline.translation.requires_macos26")
        case .undetectedLanguage:
            String(localized: "offline.translation.undetected_language")
        case .onlineServicesDisabled:
            String(localized: "offline.translation.online_services_disabled")
        }
    }
}
