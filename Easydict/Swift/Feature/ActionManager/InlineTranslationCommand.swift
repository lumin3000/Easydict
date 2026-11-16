//
//  InlineTranslationCommand.swift
//  Easydict
//
//  Copyright © 2026 izual. All rights reserved.
//

import Foundation

/// A completed `/en Chinese、` command immediately before the caret. AX ranges use UTF-16.
struct InlineTranslationCommand {
    // MARK: Lifecycle

    init?(fullText: String, selection: NSRange) {
        let value = fullText as NSString
        guard selection.length == 0, selection.location > 0,
              selection.location <= value.length else { return nil }

        let prefix = value.substring(to: selection.location)
        guard let expression = try? NSRegularExpression(pattern: #"(?:^|(?<=\s))/en[ \t]+([^\\|、]+)[\\|、]\z"#),
              let match = expression.firstMatch(
                  in: prefix,
                  range: NSRange(location: 0, length: (prefix as NSString).length)
              )
        else { return nil }

        let source = (prefix as NSString).substring(with: match.range(at: 1))
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard source.range(of: #"\p{Han}"#, options: .regularExpression) != nil else { return nil }

        self.fullText = fullText
        self.selection = selection
        self.range = match.range
        self.text = source
    }

    // MARK: Internal

    let fullText: String
    let selection: NSRange
    let range: NSRange
    let text: String

    /// Reject stale results after edits or caret movement, including edits outside the command.
    func matches(fullText: String, selection: NSRange) -> Bool {
        self.fullText == fullText && self.selection == selection
    }
}
