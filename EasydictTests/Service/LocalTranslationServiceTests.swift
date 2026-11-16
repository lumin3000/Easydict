//
//  LocalTranslationServiceTests.swift
//  EasydictTests
//
//  Copyright © 2026 izual. All rights reserved.
//

import Foundation
import Testing
import Translation

@testable import Easydict

@MainActor
@Suite("Installed Apple Translation", .tags(.unit))
struct LocalTranslationServiceTests {
    @available(macOS 26.0, *)
    @Test("Installed-language session cannot request downloads")
    func forbidsDownloads() {
        let session = TranslationSession(
            installedSource: Locale.Language(identifier: "zh-Hans"),
            target: Locale.Language(identifier: "en")
        )
        #expect(session.canRequestDownloads == false)
    }

    @available(macOS 26.0, *)
    @Test("An unspecified target fails without another provider")
    func rejectsAutomaticTarget() async {
        await #expect(throws: LocalTranslationError.unsupportedPair) {
            try await LocalTranslationService().translate("Hello", from: .english, to: .auto)
        }
    }

    @available(macOS 26.0, *)
    @Test("Real installed Chinese-English model translates text", .tags(.requiresLocalEnvironment))
    func translatesLocally() async throws {
        let result = try await LocalTranslationService().translate(
            "你好，世界！", from: .auto, to: .english
        ).lowercased()
        #expect(result.contains("hello"))
        #expect(result.contains("world"))
    }

    @available(macOS 26.0, *)
    @Test("Missing language assets fail without a download or fallback", .tags(.requiresLocalEnvironment))
    func missingAssets() async throws {
        let status = await LanguageAvailability().status(
            from: Locale.Language(identifier: "fr"), to: Locale.Language(identifier: "en")
        )
        try #require(status == .supported, "This local test requires uninstalled French assets")
        await #expect(throws: LocalTranslationError.languagesMissing) {
            try await LocalTranslationService().translate("Bonjour", from: .french, to: .english)
        }
    }
}
