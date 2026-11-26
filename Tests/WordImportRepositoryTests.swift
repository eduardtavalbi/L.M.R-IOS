import XCTest
@testable import LMR

final class WordImportRepositoryTests: XCTestCase {
    func testBatchImportCreatesWordsAndOptionalMetadata() throws {
        let repository = LibraryRepository(database: try DatabaseManager.inMemory())
        let language = try repository.createLanguage(name: "English")
        let set = try repository.createSet(languageID: language.id, name: "Basics")
        let drafts = [
            WordImportDraft(text: "hello", translation: "привет", transcription: "həˈləʊ", example: "Hello there."),
            WordImportDraft(text: "book", translation: "книга")
        ]

        let summary = try repository.importWords(drafts, intoSet: set.id)
        let words = try repository.fetchWords(inSet: set.id)

        XCTAssertEqual(summary, WordImportSummary(imported: 2, merged: 0, skipped: 0))
        XCTAssertEqual(words.count, 2)
        XCTAssertEqual(words.first(where: { $0.text == "hello" })?.transcription, "həˈləʊ")
        XCTAssertEqual(words.first(where: { $0.text == "hello" })?.example, "Hello there.")
        XCTAssertNotNil(try repository.fetchProgress(for: words[0].id))
    }

    func testDuplicatePoliciesSkipKeepBothAndMergeInOneBatch() throws {
        let repository = LibraryRepository(database: try DatabaseManager.inMemory())
        let language = try repository.createLanguage(name: "English")
        let firstSet = try repository.createSet(languageID: language.id, name: "Existing")
        let importSet = try repository.createSet(languageID: language.id, name: "Imported")
        let existing = try repository.createWord(
            languageID: language.id,
            text: "hello",
            translation: "привет",
            inSet: firstSet.id
        )
        try repository.recordLearningAnswer(wordID: existing.id, knewAnswer: true)

        let summary = try repository.importWords([
            WordImportDraft(text: "hello", translation: "привет", duplicateResolution: .skip),
            WordImportDraft(text: "hello", translation: "привет", duplicateResolution: .keepBoth),
            WordImportDraft(text: "hello", translation: "привет", transcription: "həˈləʊ", example: "Hello!", duplicateResolution: .merge)
        ], intoSet: importSet.id)

        let importedSetWords = try repository.fetchWords(inSet: importSet.id)
        let updatedExisting = try XCTUnwrap(try repository.fetchWords(inSet: firstSet.id).first)

        XCTAssertEqual(summary, WordImportSummary(imported: 1, merged: 1, skipped: 1))
        XCTAssertEqual(importedSetWords.count, 2)
        XCTAssertEqual(updatedExisting.id, existing.id)
        XCTAssertEqual(updatedExisting.transcription, "həˈləʊ")
        XCTAssertEqual(updatedExisting.example, "Hello!")
        XCTAssertEqual(try repository.fetchProgress(for: existing.id)?.correctAnswers, 1)
    }

    func testInvalidRowRollsBackEntireImportBatch() throws {
        let repository = LibraryRepository(database: try DatabaseManager.inMemory())
        let language = try repository.createLanguage(name: "English")
        let set = try repository.createSet(languageID: language.id, name: "Basics")

        XCTAssertThrowsError(try repository.importWords([
            WordImportDraft(text: "hello", translation: "привет"),
            WordImportDraft(text: "book", translation: " ")
        ], intoSet: set.id))

        XCTAssertTrue(try repository.fetchWords(inSet: set.id).isEmpty)
    }

    func testImportRejectsUnknownSetAndLeavesDatabaseUnchanged() throws {
        let repository = LibraryRepository(database: try DatabaseManager.inMemory())
        let language = try repository.createLanguage(name: "English")
        let set = try repository.createSet(languageID: language.id, name: "Basics")

        XCTAssertThrowsError(
            try repository.importWords([
                WordImportDraft(text: "hello", translation: "привет")
            ], intoSet: "missing-set")
        ) { error in
            XCTAssertEqual(error as? LibraryRepositoryError, .setNotFound)
        }
        XCTAssertTrue(try repository.fetchWords(inSet: set.id).isEmpty)
    }
}
