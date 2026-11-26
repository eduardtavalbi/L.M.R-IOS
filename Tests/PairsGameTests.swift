import XCTest
@testable import LMR

final class PairsGameTests: XCTestCase {
    func testCreatesTwoCardsForEachSelectedWordAndShufflesSides() {
        let words = [
            Word(languageID: "en", text: "hello", translation: "привет"),
            Word(languageID: "en", text: "water", translation: "вода"),
            Word(languageID: "en", text: "book", translation: "книга")
        ]

        let cards = PairsGameEngine.makeCards(from: words, pairCount: 2)

        XCTAssertEqual(cards.count, 4)
        XCTAssertEqual(Set(cards.map(\.wordID)).count, 2)
        for wordID in Set(cards.map(\.wordID)) {
            XCTAssertEqual(cards.filter { $0.wordID == wordID }.count, 2)
            XCTAssertEqual(Set(cards.filter { $0.wordID == wordID }.map(\.side)).count, 2)
        }
    }

    func testMatchingRequiresSameWordAndOppositeSides() {
        let prompt = PairsCard(id: "1-prompt", wordID: "1", side: .prompt, text: "hello")
        let answer = PairsCard(id: "1-answer", wordID: "1", side: .answer, text: "привет")
        let otherAnswer = PairsCard(id: "2-answer", wordID: "2", side: .answer, text: "вода")
        let otherPrompt = PairsCard(id: "1-other-prompt", wordID: "1", side: .prompt, text: "hello")

        XCTAssertTrue(PairsGameEngine.isMatch(prompt, answer))
        XCTAssertFalse(PairsGameEngine.isMatch(prompt, otherAnswer))
        XCTAssertFalse(PairsGameEngine.isMatch(prompt, otherPrompt))
    }

    func testReturnsNoGameWhenThereAreFewerThanTwoValidWords() {
        let one = Word(languageID: "en", text: "hello", translation: "привет")
        let blank = Word(languageID: "en", text: " ", translation: " ")

        XCTAssertTrue(PairsGameEngine.makeCards(from: [one]).isEmpty)
        XCTAssertTrue(PairsGameEngine.makeCards(from: [one, blank]).isEmpty)
        XCTAssertTrue(PairsGameEngine.makeCards(from: [one, one], pairCount: 1).isEmpty)
    }

    func testPairCountIsCappedByAvailableWords() {
        let words = [
            Word(languageID: "en", text: "one", translation: "один"),
            Word(languageID: "en", text: "two", translation: "два")
        ]

        XCTAssertEqual(PairsGameEngine.makeCards(from: words, pairCount: 8).count, 4)
    }
}
