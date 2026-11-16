//
//  InlineTranslationController.swift
//  Easydict
//
//  Copyright © 2026 izual. All rights reserved.
//

import AppKit
import ApplicationServices

/// Translates completed inline commands without changing focus or using the clipboard.
/// Owned by EventMonitor and used on the main queue, alongside its existing input monitors.
final class InlineTranslationController {
    // MARK: Internal

    /// Invalidate on new input, clicks, app switches and monitor shutdown.
    func cancel() {
        generation += 1
        task?.cancel()
        task = nil
        pendingSnapshot = nil
        completedReplacement = nil
    }

    /// Follow the active app's focused input and its committed text/selection changes.
    func start() {
        isRunning = true
        updateFrontmostApplication()
    }

    func updateFrontmostApplication() {
        guard isRunning else { return }
        cancel()
        inputObserver.start()
    }

    func stop() {
        isRunning = false
        cancel()
        inputObserver.stop()
    }

    func refreshFocus() {
        inputObserver.refreshFocus()
    }

    // MARK: Private

    private struct Snapshot {
        let element: AXUIElement
        let pid: pid_t
        let text: String
        let selection: NSRange
        let canSetValue: Bool
    }

    private struct CompletedReplacement {
        let original: Snapshot
        let text: String
        let caret: Int
    }

    private var task: Task<(), Never>?
    private var generation = 0
    private var isRunning = false
    private var pendingSnapshot: Snapshot?
    private var completedReplacement: CompletedReplacement?
    private lazy var inputObserver = FocusedInputObserver { [weak self] in
        self?.inspectFocusedInput()
    }

    private func inspectFocusedInput() {
        guard let snapshot = capture() else {
            cancel()
            return
        }

        if let completedReplacement {
            guard CFEqual(snapshot.element, completedReplacement.original.element),
                  snapshot.pid == completedReplacement.original.pid else {
                cancel()
                return
            }
            guard snapshot.text == completedReplacement.text else {
                if snapshot.text != completedReplacement.original.text { cancel() }
                return
            }
            // Web inputs update their AX text tree asynchronously. Position the caret only
            // after the new value is observable, so offsets refer to the translated text.
            self.completedReplacement = nil
            var caret = CFRange(location: completedReplacement.caret, length: 0)
            if let value = AXValueCreate(.cfRange, &caret) {
                AXUIElementSetAttributeValue(snapshot.element, kAXSelectedTextRangeAttribute as CFString, value)
            }
            return
        }

        guard let command = InlineTranslationCommand(fullText: snapshot.text, selection: snapshot.selection) else {
            cancel()
            return
        }

        // AX often emits value and selection notifications for the same edit.
        if let pendingSnapshot,
           CFEqual(pendingSnapshot.element, snapshot.element),
           pendingSnapshot.pid == snapshot.pid,
           command.matches(fullText: pendingSnapshot.text, selection: pendingSnapshot.selection) {
            return
        }

        cancel()
        pendingSnapshot = snapshot
        let requestGeneration = generation
        task = Task { @MainActor [weak self] in
            guard let self else { return }
            defer {
                if generation == requestGeneration {
                    task = nil
                    pendingSnapshot = nil
                }
            }
            guard !Task.isCancelled else { return }

            do {
                // Use the same built-in provider as Translate and Replace, in a dedicated request instance.
                let service = BuiltInAIService()
                service.queryType = .translation
                service.queryModel.inputText = command.text
                service.queryModel.userTargetLanguage = .english
                let result = try await service.translate(command.text, from: .auto, to: .english)
                try Task.checkCancellation()
                if let error = result.error { throw error }
                guard let translation = result.translatedText?.trimmingCharacters(in: .whitespacesAndNewlines),
                      !translation.isEmpty,
                      generation == requestGeneration,
                      let current = capture(),
                      CFEqual(snapshot.element, current.element),
                      snapshot.pid == current.pid,
                      command.matches(fullText: current.text, selection: current.selection)
                else { return }

                replace(command, with: translation, in: snapshot)
            } catch is CancellationError {
                // Normal editing invalidates an outstanding translation.
            } catch {
                logError("Inline English translation failed: \(error.localizedDescription)")
            }
        }
    }

    private func capture() -> Snapshot? {
        guard AXIsProcessTrusted(),
              let app = NSWorkspace.shared.frontmostApplication else { return nil }
        let application = AXUIElementCreateApplication(app.processIdentifier)
        guard let focused = attribute(application, kAXFocusedUIElementAttribute),
              CFGetTypeID(focused) == AXUIElementGetTypeID() else { return nil }
        let element = unsafeBitCast(focused, to: AXUIElement.self)
        let role = attribute(element, kAXRoleAttribute) as? String
        guard [kAXTextFieldRole, kAXTextAreaRole, kAXComboBoxRole].contains(role ?? ""),
              attribute(element, kAXSubroleAttribute) as? String != kAXSecureTextFieldSubrole,
              isSettable(element, kAXValueAttribute) || isSettable(element, kAXSelectedTextAttribute),
              isSettable(element, kAXSelectedTextRangeAttribute),
              let text = attribute(element, kAXValueAttribute) as? String,
              let rangeValue = attribute(element, kAXSelectedTextRangeAttribute),
              CFGetTypeID(rangeValue) == AXValueGetTypeID() else { return nil }
        var range = CFRange()
        let value = unsafeBitCast(rangeValue, to: AXValue.self)
        guard AXValueGetValue(value, .cfRange, &range), range.location >= 0, range.length >= 0 else { return nil }
        return Snapshot(
            element: element,
            pid: app.processIdentifier,
            text: text,
            selection: NSRange(location: range.location, length: range.length),
            canSetValue: isSettable(element, kAXValueAttribute)
        )
    }

    private func replace(_ command: InlineTranslationCommand, with translation: String, in snapshot: Snapshot) {
        let element = snapshot.element
        var range = CFRange(location: command.range.location, length: command.range.length)
        let result: AXError
        if snapshot.canSetValue {
            // A single value update also avoids asynchronous select/insert races in web inputs.
            result = AXUIElementSetAttributeValue(
                element, kAXValueAttribute as CFString, command.replacingCommand(with: translation) as CFString
            )
        } else {
            guard let value = AXValueCreate(.cfRange, &range),
                  AXUIElementSetAttributeValue(element, kAXSelectedTextRangeAttribute as CFString, value) == .success
            else { return }
            result = AXUIElementSetAttributeValue(
                element, kAXSelectedTextAttribute as CFString, translation as CFString
            )
        }
        if result == .success {
            completedReplacement = CompletedReplacement(
                original: snapshot,
                text: command.replacingCommand(with: translation),
                caret: command.range.location + (translation as NSString).length
            )
            inspectFocusedInput()
        } else {
            // A failed write must leave the original selection intact as well as the original text.
            range = CFRange(location: command.selection.location, length: command.selection.length)
            if let original = AXValueCreate(.cfRange, &range) {
                AXUIElementSetAttributeValue(element, kAXSelectedTextRangeAttribute as CFString, original)
            }
            logError("Inline translation replacement failed: \(result.rawValue)")
        }
    }

    private func attribute(_ element: AXUIElement, _ name: String) -> CFTypeRef? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, name as CFString, &value) == .success else { return nil }
        return value
    }

    private func isSettable(_ element: AXUIElement, _ name: String) -> Bool {
        var settable = DarwinBoolean(false)
        return AXUIElementIsAttributeSettable(element, name as CFString, &settable) == .success && settable.boolValue
    }
}
