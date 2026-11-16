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
    }

    /// Key-up observes committed text, including Chinese IME input, rather than raw key strokes.
    func handleKeyUp(_ event: NSEvent) {
        let modifiers = event.modifierFlags.intersection([.command, .control, .option])
        let isTerminator = ["、", "|", "\\"].contains(event.characters ?? "") && modifiers.isEmpty
        let isPaste = event.charactersIgnoringModifiers?.lowercased() == "v" && modifiers == .command
        guard isTerminator || isPaste else { return }

        cancel()
        let requestGeneration = generation
        task = Task { @MainActor [weak self] in
            guard let self else { return }
            defer {
                if generation == requestGeneration { task = nil }
            }
            guard !Task.isCancelled, let snapshot = capture(),
                  let command = InlineTranslationCommand(fullText: snapshot.text, selection: snapshot.selection)
            else { return }

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

                replace(command, with: translation, in: snapshot.element)
            } catch is CancellationError {
                // Normal editing invalidates an outstanding translation.
            } catch {
                logError("Inline English translation failed: \(error.localizedDescription)")
            }
        }
    }

    // MARK: Private

    private struct Snapshot {
        let element: AXUIElement
        let pid: pid_t
        let text: String
        let selection: NSRange
    }

    private var task: Task<(), Never>?
    private var generation = 0

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
              isSettable(element, kAXSelectedTextAttribute),
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
            selection: NSRange(location: range.location, length: range.length)
        )
    }

    private func replace(_ command: InlineTranslationCommand, with translation: String, in element: AXUIElement) {
        var range = CFRange(location: command.range.location, length: command.range.length)
        guard let value = AXValueCreate(.cfRange, &range),
              AXUIElementSetAttributeValue(element, kAXSelectedTextRangeAttribute as CFString, value) == .success
        else { return }

        let result = AXUIElementSetAttributeValue(
            element,
            kAXSelectedTextAttribute as CFString,
            translation as CFString
        )
        if result == .success {
            range = CFRange(location: command.range.location + (translation as NSString).length, length: 0)
            if let caret = AXValueCreate(.cfRange, &range) {
                AXUIElementSetAttributeValue(element, kAXSelectedTextRangeAttribute as CFString, caret)
            }
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
