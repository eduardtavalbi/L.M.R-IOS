import XCTest
@testable import LMR

final class LearningQueueTests: XCTestCase {
    func testMixQueueCombinesSetsAndDeduplicatesSharedWords() throws {
        let repository = LibraryRepository(database: try DatabaseManager.inMemory())
        let language = try repository.createLanguage(name: "English")
        let first = try repository.createSet(languageID: language.id, name: "First")
        let second = try repository.createSet(languageID: language.id, name: "Second")
        let shared = try repository.createWord(languageID: language.id, text: "hello", translation: "привет", inSet: first.id)
        let unique = try repository.createWord(languageID: language.id, text: "thanks", translation: "спасибо", inSet: second.id)
        try repository.addWord(shared.id, toSet: second.id)
        let queue = try repository.fetchLearningQueue(inSets: [first.id, second.id, first.id])
        XCTAssertEqual(Set(queue.map(\.id)), Set([shared.id, unique.id]))
        XCTAssertEqual(queue.count, 2)
    }

    func testWeakWordsIncludeFutureDueErrorsOnlyOnce() throws {
        let repository = LibraryRepository(database: try DatabaseManager.inMemory())
        let language = try repository.createLanguage(name: "English")
        let first = try repository.createSet(languageID: language.id, name: "First")
        let second = try repository.createSet(languageID: language.id, name: "Second")
        let weak = try repository.createWord(languageID: language.id, text: "difficult", translation: "сложный", inSet: first.id)
        let newWord = try repository.createWord(languageID: language.id, text: "new", translation: "новый", inSet: second.id)
        try repository.addWord(weak.id, toSet: second.id)
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        try repository.recordLearningAnswer(wordID: weak.id, knewAnswer: false, reviewedAt: now)
        let weakWords = try repository.fetchWeakWords(inSets: [first.id, second.id])
        XCTAssertEqual(weakWords.map(\.id), [weak.id])
        XCTAssertFalse(weakWords.contains { $0.id == newWord.id })
        XCTAssertEqual(try repository.fetchLearningQueue(inSets: [first.id, second.id], dueAt: now).count, 1)
    }

    func testEmptyMixSelectionReturnsNoWords() throws {
        let repository = LibraryRepository(database: try DatabaseManager.inMemory())
        XCTAssertTrue(try repository.fetchLearningQueue(inSets: []).isEmpty)
        XCTAssertTrue(try repository.fetchWeakWords(inSets: []).isEmpty)
    }
}