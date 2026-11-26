import XCTest
@testable import LMR

final class AudioChoiceGameTests: XCTestCase {
    func testOptionsContainCorrectTranslationAndUniqueDistractors() {
        let target = Word(languageID: "en", text: "hello", translation: "привет")
        let words = [
            target,
            Word(languageID: "en", text: "goodbye", translation: "пока"),
            Word(languageID: "en", text: "thanks", translation: "спасибо"),
            Word(languageID: "en", text: "hi", translation: "ПРИВЕТ"),
            Word(languageID: "en", text: "water", translation: "вода")
        ]

        let options = AudioChoiceGameEngine.options(for: target, from: words)

        XCTAssertEqual(options.count, 4)
        XCTAssertTrue(options.contains("привет"))
        XCTAssertEqual(Set(options.map { $0.lowercased() }).count, options.count)
    }

    func testSmallSetReturnsAvailableChoices() {
        let target = Word(languageID: "en", text: "cat", translation: "кот")
        let other = Word(languageID: "en", text: "dog", translation: "собака")

        XCTAssertEqual(
            Set(AudioChoiceGameEngine.options(for: target, from: [target, other])),
            Set(["кот", "собака"])
        )
    }

    func testRejectsWordsWithoutPromptOrTranslation() {
        let emptyPrompt = Word(languageID: "en", text: " ", translation: "word")
        let emptyAnswer = Word(languageID: "en", text: "word", translation: " ")

        XCTAssertFalse(AudioChoiceGameEngine.canPlay(emptyPrompt))
        XCTAssertFalse(AudioChoiceGameEngine.canPlay(emptyAnswer))
    }

    func testGameRequiresAtLeastTwoDistinctTranslations() {
        let first = Word(languageID: "en", text: "hello", translation: "привет")
        let duplicate = Word(languageID: "en", text: "hi", translation: "ПРИВЕТ")
        let distinct = Word(languageID: "en", text: "bye", translation: "пока")

        XCTAssertFalse(AudioChoiceGameEngine.canPlayGame(with: [first, duplicate]))
        XCTAssertTrue(AudioChoiceGameEngine.canPlayGame(with: [first, duplicate, distinct]))
    }
}
