//
//  FocusedInputObserver.swift
//  Easydict
//
//  Copyright © 2026 izual. All rights reserved.
//

import AppKit
import ApplicationServices

/// Watches text and selection changes in the active app, including IME commits and paste.
/// Owned by EventMonitor's controller; start/stop and callbacks run on the main run loop.
final class FocusedInputObserver {
    // MARK: Lifecycle

    init(onChange: @escaping () -> ()) {
        self.onChange = onChange
    }

    // MARK: Internal

    func start() {
        stop()
        guard AXIsProcessTrusted(), let app = NSWorkspace.shared.frontmostApplication else { return }
        let callback: AXObserverCallback = { _, _, notification, context in
            guard let context else { return }
            let owner = Unmanaged<FocusedInputObserver>.fromOpaque(context).takeUnretainedValue()
            if notification as String == kAXFocusedUIElementChangedNotification {
                owner.refreshFocus()
            } else {
                owner.scheduleChange()
            }
        }
        var newObserver: AXObserver?
        guard AXObserverCreate(app.processIdentifier, callback, &newObserver) == .success,
              let newObserver else { return }
        observer = newObserver
        let application = AXUIElementCreateApplication(app.processIdentifier)
        self.application = application
        AXObserverAddNotification(
            newObserver, application, kAXFocusedUIElementChangedNotification as CFString, context
        )
        CFRunLoopAddSource(CFRunLoopGetMain(), AXObserverGetRunLoopSource(newObserver), .commonModes)
        refreshFocus()
    }

    func stop() {
        changeWorkItem?.cancel()
        changeWorkItem = nil
        if let observer {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), AXObserverGetRunLoopSource(observer), .commonModes)
        }
        observer = nil
        application = nil
        focusedElement = nil
    }

    /// Mouse-up also refreshes focus for apps that do not emit focused-element notifications.
    func refreshFocus() {
        guard let observer, let application else { return }
        if let focusedElement {
            for notification in textNotifications {
                AXObserverRemoveNotification(observer, focusedElement, notification as CFString)
            }
        }
        focusedElement = nil
        var value: CFTypeRef?
        if AXUIElementCopyAttributeValue(application, kAXFocusedUIElementAttribute as CFString, &value) == .success,
           let value, CFGetTypeID(value) == AXUIElementGetTypeID() {
            let element = unsafeBitCast(value, to: AXUIElement.self)
            focusedElement = element
            for notification in textNotifications {
                AXObserverAddNotification(observer, element, notification as CFString, context)
            }
        }
        scheduleChange()
    }

    // MARK: Private

    private let onChange: () -> ()
    private let textNotifications = [kAXValueChangedNotification, kAXSelectedTextChangedNotification]
    private var observer: AXObserver?
    private var application: AXUIElement?
    private var focusedElement: AXUIElement?
    private var changeWorkItem: DispatchWorkItem?

    private var context: UnsafeMutableRawPointer {
        Unmanaged.passUnretained(self).toOpaque()
    }

    private func scheduleChange() {
        changeWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            guard let self, observer != nil else { return }
            onChange()
        }
        changeWorkItem = workItem
        DispatchQueue.main.async(execute: workItem)
    }
}
