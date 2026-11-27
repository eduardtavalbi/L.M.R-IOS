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
    func testSetWordCountUsesMembershipsWithoutLoadingCards() throws {
        let repository = LibraryRepository(database: try DatabaseManager.inMemory())
        let language = try repository.createLanguage(name: "English")
        let first = try repository.createSet(languageID: language.id, name: "First")
        let second = try repository.createSet(languageID: language.id, name: "Second")
        let shared = try repository.createWord(languageID: language.id, text: "hello", translation: "привет", inSet: first.id)
        _ = try repository.createWord(languageID: language.id, text: "thanks", translation: "спасибо", inSet: first.id)
        try repository.addWord(shared.id, toSet: second.id)

        XCTAssertEqual(try repository.fetchWordCount(inSet: first.id), 2)
        XCTAssertEqual(try repository.fetchWordCount(inSet: second.id), 1)
        XCTAssertEqual(try repository.fetchWordCount(inSet: "missing"), 0)
    }

    func testDueWordCountMatchesReviewQueueWithoutMaterializingWords() throws {
        let repository = LibraryRepository(database: try DatabaseManager.inMemory())
        let language = try repository.createLanguage(name: "English")
        let set = try repository.createSet(languageID: language.id, name: "Review")
        let newWord = try repository.createWord(languageID: language.id, text: "new", translation: "новый", inSet: set.id)
        let dueWord = try repository.createWord(languageID: language.id, text: "due", translation: "срок", inSet: set.id)
        let futureWord = try repository.createWord(languageID: language.id, text: "future", translation: "позже", inSet: set.id)
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        try repository.recordLearningAnswer(wordID: dueWord.id, knewAnswer: true, reviewedAt: now.addingTimeInterval(-86_400))
        try repository.recordLearningAnswer(wordID: futureWord.id, knewAnswer: true, reviewedAt: now.addingTimeInterval(86_400))

        XCTAssertEqual(try repository.fetchDueWordCount(inSet: set.id, dueAt: now), 2)
        XCTAssertEqual(
            try repository.fetchDueWordCount(inSet: set.id, dueAt: now),
            try repository.fetchLearningQueue(inSet: set.id, dueAt: now).count
        )
        XCTAssertTrue([newWord.id, dueWord.id].allSatisfy { id in
            (try? repository.fetchLearningQueue(inSet: set.id, dueAt: now).contains { $0.id == id }) == true
        })
    }

}