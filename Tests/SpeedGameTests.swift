import XCTest
@testable import LMR

final class SpeedGameTests: XCTestCase {
    func testEligibleWordsExcludeEmptyPromptAndAnswer() {
        let words = [
            Word(languageID: "en", text: "hello", translation: "привет"),
            Word(languageID: "en", text: " ", translation: "пусто"),
            Word(languageID: "en", text: "empty", translation: " ")
        ]
        XCTAssertEqual(SpeedGameEngine.eligibleWords(words).map(\.text), ["hello"])
    }

    func testAnswerNormalizationMatchesStudyTyping() {
        XCTAssertTrue(SpeedGameEngine.answersMatch("  HELLO  ", expected: "hello"))
        XCTAssertFalse(SpeedGameEngine.answersMatch("", expected: "hello"))
    }

    func testPointsIncreaseAfterEveryFiveCorrectInARow() {
        XCTAssertEqual(SpeedGameEngine.points(forCorrectAnswer: 1), 1)
        XCTAssertEqual(SpeedGameEngine.points(forCorrectAnswer: 4), 1)
        XCTAssertEqual(SpeedGameEngine.points(forCorrectAnswer: 5), 1)
        XCTAssertEqual(SpeedGameEngine.points(forCorrectAnswer: 6), 2)
        XCTAssertEqual(SpeedGameEngine.points(forCorrectAnswer: 10), 2)
        XCTAssertEqual(SpeedGameEngine.points(forCorrectAnswer: 11), 3)
    }
}
