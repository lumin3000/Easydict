//
//  LocalOnlyPolicy.swift
//  Easydict
//
//  Copyright © 2026 izual. All rights reserved.
//

import Defaults
import Foundation

/// This custom build only exposes services that process text on this Mac.
@objc(EZLocalOnlyPolicy)
@objcMembers
final class LocalOnlyPolicy: NSObject {
    static let isEnabled = true

    static func allowsService(_ identifier: String) -> Bool {
        let base = String(identifier.split(separator: "#", maxSplits: 1).first ?? "")
        return [ServiceType.apple.rawValue, ServiceType.appleDictionary.rawValue, ServiceType.mDict.rawValue]
            .contains(base)
    }

    /// Normalize existing preferences before provider, updater or analytics startup.
    static func configureDefaults() {
        Defaults[.enableAppleOfflineTranslation] = true
        Defaults[.languageDetectOptimize] = .none
        Defaults[.ocrServiceID] = ServiceType.apple.rawValue
        Defaults[.enableYoudaoOCR] = false
        Defaults[.defaultTTSServiceType] = .apple
        Defaults[.preferYoudaoTTSForEnglishWord] = false
        Defaults[.showGoogleQuickLink] = false
        Defaults[.showEudicQuickLink] = false
        Defaults[.allowAnalytics] = false
        Defaults[.allowCrashLog] = false
        Defaults[Defaults.Key<Bool>("SUEnableAutomaticChecks", default: false)] = false

        let storage = LocalStorage.shared()
        for window in [EZWindowType.main, .fixed, .mini] {
            storage.setServiceEnabled(true, serviceTypeId: ServiceType.apple.rawValue, windowType: window)
            storage.setEnabledQuery(true, serviceType: .apple, serviceId: "", windowType: window)
        }
    }
}
