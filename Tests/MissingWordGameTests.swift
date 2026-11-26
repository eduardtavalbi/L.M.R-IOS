import XCTest
@testable import LMR

final class MissingWordGameTests: XCTestCase {
    func testEligibleWordsRequireExampleContainingPrompt() {
        let eligible = Word(languageID: "en", text: "apple", translation: "яблоко", example: "I eat an apple.")
        let noExample = Word(languageID: "en", text: "pear", translation: "груша")
        let unrelatedExample = Word(languageID: "en", text: "orange", translation: "апельсин", example: "I like apples.")

        XCTAssertEqual(MissingWordGameEngine.eligibleWords([eligible, noExample, unrelatedExample]).map(\.text), ["apple"])
    }

    func testSentenceReplacesEveryCaseInsensitiveOccurrence() {
        let word = Word(languageID: "en", text: "apple", translation: "яблоко", example: "An apple a day keeps the APPLE doctor away.")

        XCTAssertEqual(
            MissingWordGameEngine.sentenceWithMissingWord(for: word),
            "An _______ a day keeps the _______ doctor away."
        )
    }

    func testSentenceIsUnavailableWhenPromptDoesNotOccur() {
        let word = Word(languageID: "en", text: "apple", translation: "яблоко", example: "I like fruit.")

        XCTAssertNil(MissingWordGameEngine.sentenceWithMissingWord(for: word))
    }

    func testAnswerMatchingUsesTypingNormalization() {
        XCTAssertTrue(MissingWordGameEngine.answersMatch("  APPLE  ", expected: "apple"))
        XCTAssertFalse(MissingWordGameEngine.answersMatch("", expected: "apple"))
    }
}
