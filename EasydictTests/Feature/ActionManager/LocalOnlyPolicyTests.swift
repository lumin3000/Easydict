//
//  LocalOnlyPolicyTests.swift
//  EasydictTests
//
//  Copyright © 2026 izual. All rights reserved.
//

import Defaults
import Testing

@testable import Easydict

@MainActor
@Suite("Local-only service policy", .tags(.unit))
struct LocalOnlyPolicyTests {
    @Test("Online providers and local CLI agents cannot be instantiated")
    func excludesNetworkProviders() {
        let forbidden: [ServiceType] = [
            .builtInAI, .google, .youdao, .deepL, .openAI, .codexCLI,
            .claudeCode, .gitHubCopilot, .ollama, .customOpenAI,
        ]
        for type in forbidden {
            #expect(QueryServiceFactory.shared.service(withTypeId: type.rawValue) == nil)
            #expect(LocalStorage.shared().service(type.rawValue, windowType: .fixed) == nil)
            #expect(QueryServiceFactory.shared.metadata(withTypeId: type.rawValue + "#saved-instance") == nil)
        }
        #expect(Set(QueryServiceFactory.shared.allServiceTypeIDs) == Set([
            ServiceType.apple.rawValue, ServiceType.appleDictionary.rawValue, ServiceType.mDict.rawValue,
        ]))
    }

    @Test("All query windows use local services and enable Apple translation")
    func localWindowServices() {
        for window in [EZWindowType.main, .fixed, .mini] {
            let services = LocalStorage.shared().enabledServices(window)
            #expect(services.contains { $0.serviceType() == .apple })
            #expect(services.allSatisfy { LocalOnlyPolicy.allowsService($0.serviceType().rawValue) })
        }
        #expect(MyConfiguration.shared.defaultTTSServiceType == .apple)
        #expect(Defaults[.enableAppleOfflineTranslation])
        #expect(!Defaults[.enableYoudaoOCR])
        #expect(!Defaults[.allowAnalytics])
        #expect(!Defaults[.allowCrashLog])
    }

    @Test("Direct legacy online queries are rejected before requesting a translation")
    func rejectsDirectOnlineQuery() async {
        let model = QueryModel()
        model.inputText = "你好"
        model.userTargetLanguage = .english
        await #expect(throws: LocalTranslationError.onlineServicesDisabled) {
            try await GoogleService().startQuery(model)
        }
        await #expect(throws: LocalTranslationError.onlineServicesDisabled) {
            try await BuiltInAIService().translate("你好", from: .simplifiedChinese, to: .english)
        }
    }
}
