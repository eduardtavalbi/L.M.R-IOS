import XCTest
@testable import LMR

final class StudyModeTests: XCTestCase {
    func testTypingAnswerIgnoresCaseAndSurroundingWhitespace() {
        XCTAssertTrue(StudyModeEngine.answersMatch("  HELLO   world ", expected: "hello world"))
        XCTAssertTrue(StudyModeEngine.answersMatch("café", expected: "cafe"))
        XCTAssertFalse(StudyModeEngine.answersMatch("hello", expected: "hello!"))
        XCTAssertFalse(StudyModeEngine.answersMatch("   ", expected: "hello"))
    }

    func testMultipleChoiceContainsCorrectAnswerAndUniqueDistractors() {
        let languageID = "language"
        let target = Word(languageID: languageID, text: "你好", translation: "hello")
        let words = [
            target,
            Word(languageID: languageID, text: "再见", translation: "goodbye"),
            Word(languageID: languageID, text: "谢谢", translation: "thanks"),
            Word(languageID: languageID, text: "您好", translation: "HELLO"),
            Word(languageID: languageID, text: "水", translation: "water")
        ]

        let options = StudyModeEngine.multipleChoiceOptions(for: target, from: words)
        XCTAssertEqual(options.count, 4)
        XCTAssertTrue(options.contains("hello"))
        XCTAssertEqual(Set(options.map { $0.lowercased() }).count, options.count)
    }

    func testMultipleChoiceGracefullyReturnsAvailableOptionsWhenSetIsSmall() {
        let target = Word(languageID: "language", text: "猫", translation: "cat")
        let onlyOther = Word(languageID: "language", text: "狗", translation: "dog")
        let options = StudyModeEngine.multipleChoiceOptions(for: target, from: [target, onlyOther])
        XCTAssertEqual(Set(options), Set(["cat", "dog"]))
    }

    func testMultipleChoiceRejectsInvalidLimitsAndEmptyCorrectAnswer() {
        let target = Word(languageID: "language", text: "猫", translation: " ")
        XCTAssertTrue(StudyModeEngine.multipleChoiceOptions(for: target, from: [target]).isEmpty)
        XCTAssertTrue(StudyModeEngine.multipleChoiceOptions(for: target, from: [target], limit: 1).isEmpty)
    }
}
