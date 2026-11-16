//
//  InlineTranslationCommandTests.swift
//  EasydictTests
//
//  Copyright © 2026 izual. All rights reserved.
//

import Foundation
import Testing

@testable import Easydict

@Suite("Inline English Translation", .tags(.unit))
struct InlineTranslationCommandTests {
    // MARK: Internal

    @Test("Recognizes committed Chinese and trims command whitespace", arguments: [
        "/en 你好、", "/en 你好|", "/en 你好\\", "/en\t你好\\", "/en   你好  \\",
        "/en 繁體中文、", "/en 明天 review PR|", "/en 第一行\n第二行、",
    ])
    func recognizesCommand(_ value: String) throws {
        let command = try #require(parse(value))
        #expect(!command.text.hasPrefix(" "))
        #expect(!command.text.hasSuffix(" "))
        #expect(command.range == NSRange(location: 0, length: (value as NSString).length))
    }

    @Test("Ignores incomplete, empty, non-Chinese and non-command input", arguments: [
        "/en 你好", "/en \\", "/en hello\\", "/en你好\\", "/EN 你好\\", "/fr 你好\\",
        "https://example.com/en 你好\\", "word/en 你好\\", "/en 你好\\ suffix", "/en 你好、\n", "/en 你好| ",
    ])
    func rejectsOtherInput(_ value: String) {
        #expect(parse(value) == nil)
    }

    @Test("Replaces only the command at the caret, preserving prefix, suffix and emoji")
    func preservesSurroundingText() throws {
        let prefix = "😀 前文 "
        let commandText = "/en 明天见\\"
        let suffix = " 后文 🚀"
        let value = prefix + commandText + suffix
        let caret = (prefix as NSString).length + (commandText as NSString).length
        let command = try #require(parse(value, caret: caret))
        #expect(command.text == "明天见")
        #expect(command.range.location == (prefix as NSString).length)
        #expect((value as NSString).replacingCharacters(in: command.range, with: "See you tomorrow")
            == "😀 前文 See you tomorrow 后文 🚀")
    }

    @Test("Uses the most recent command, leaving an earlier completed command intact")
    func multipleCommands() throws {
        let value = "/en 你好\\ /en 再见\\"
        let command = try #require(parse(value))
        #expect(command.text == "再见")
        #expect((value as NSString).replacingCharacters(in: command.range, with: "Goodbye") == "/en 你好\\ Goodbye")
    }

    @Test("All supported terminators delimit separate commands", arguments: ["、", "|", "\\"])
    func terminators(_ terminator: String) throws {
        let value = "/en 你好" + terminator + " /en 再见" + terminator
        let command = try #require(parse(value))
        #expect(command.text == "再见")
        #expect((value as NSString).replacingCharacters(in: command.range, with: "Goodbye")
            == "/en 你好" + terminator + " Goodbye")
    }

    @Test("Does not translate a selection or an invalid caret range")
    func rejectsSelection() {
        let value = "/en 你好\\"
        #expect(InlineTranslationCommand(fullText: value, selection: NSRange(location: 0, length: 7)) == nil)
        #expect(parse(value, caret: 999) == nil)
        #expect(parse(value, caret: 0) == nil)
        #expect(parse(value, caret: NSNotFound) == nil)
    }

    @Test("Rejects results after source text, surrounding text or selection changes")
    func rejectsStaleSnapshot() throws {
        let value = "/en 明天见\\"
        let command = try #require(parse(value))
        #expect(command.matches(fullText: value, selection: command.selection))
        #expect(!command.matches(fullText: "/en 昨天见\\", selection: command.selection))
        #expect(!command.matches(fullText: value + "x", selection: command.selection))
        #expect(!command.matches(fullText: value, selection: NSRange(location: 1, length: 0)))
        #expect(!command.matches(fullText: value, selection: NSRange(location: command.selection.location, length: 1)))
    }

    @Test("Translates Chinese to English using the real built-in provider", .tags(.requiresLocalEnvironment))
    @MainActor
    func realTranslation() async throws {
        let service = BuiltInAIService()
        service.queryType = .translation
        service.queryModel.inputText = "你好，世界！"
        service.queryModel.userTargetLanguage = .english
        let result = try await service.translate("你好，世界！", from: .auto, to: .english)
        #expect(result.error == nil)
        let text = try #require(result.translatedText?.lowercased())
        #expect(text.contains("hello"))
        #expect(text.contains("world"))
    }

    // MARK: Private

    private func parse(_ value: String, caret: Int? = nil) -> InlineTranslationCommand? {
        InlineTranslationCommand(
            fullText: value,
            selection: NSRange(location: caret ?? (value as NSString).length, length: 0)
        )
    }
}
