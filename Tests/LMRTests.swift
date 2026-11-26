import XCTest
@testable import LMR

final class LMRTests: XCTestCase {
    func testAppInformation() {
        XCTAssertEqual(AppInfo.name, "L.M.R.")
        XCTAssertEqual(AppInfo.fullName, "Learn. Memorize. Repeat.")
    }

    func testLanguageCategoryAndNestedCategoryPersistence() throws {
        let database = try DatabaseManager.inMemory()
        let repository = LibraryRepository(database: database)

        let language = try repository.createLanguage(name: "Chinese", code: "zh")
        let parent = try repository.createCategory(languageID: language.id, name: "Food")
        let child = try repository.createCategory(
            languageID: language.id,
            name: "Fruit",
            parentID: parent.id
        )

        XCTAssertEqual(try repository.fetchCategories(languageID: language.id), [parent, child])
    }

    func testUncategorizedSetAndMovingBetweenCategories() throws {
        let database = try DatabaseManager.inMemory()
        let repository = LibraryRepository(database: database)
        let language = try repository.createLanguage(name: "English")
        let first = try repository.createCategory(languageID: language.id, name: "Travel")
        let second = try repository.createCategory(languageID: language.id, name: "Work")
        let set = try repository.createSet(languageID: language.id, name: "Phrases")

        XCTAssertEqual(try repository.fetchSets(languageID: language.id), [set])

        try repository.moveSet(set.id, toCategory: first.id)
        XCTAssertEqual(try repository.fetchSets(languageID: language.id, categoryID: first.id), [try XCTUnwrap(
            repository.fetchSets(languageID: language.id, categoryID: first.id).first
        )])

        try repository.moveSet(set.id, toCategory: second.id)
        XCTAssertEqual(try repository.fetchSets(languageID: language.id, categoryID: second.id).first?.id, set.id)
    }

    func testWordCanBelongToMultipleSetsAndSharesProgress() throws {
        let database = try DatabaseManager.inMemory()
        let repository = LibraryRepository(database: database)
        let language = try repository.createLanguage(name: "Chinese", code: "zh")
        let firstSet = try repository.createSet(languageID: language.id, name: "Food")
        let secondSet = try repository.createSet(languageID: language.id, name: "Daily")
        let word = try repository.createWord(
            languageID: language.id,
            text: "苹果",
            translation: "яблоко",
            transcription: "píngguǒ",
            inSet: firstSet.id
        )

        try repository.addWord(word.id, toSet: secondSet.id)

        XCTAssertEqual(try repository.fetchWords(inSet: firstSet.id).map(\.id), [word.id])
        XCTAssertEqual(try repository.fetchWords(inSet: secondSet.id).map(\.id), [word.id])
        XCTAssertEqual(try repository.fetchProgress(for: word.id)?.wordID, word.id)
        XCTAssertEqual(try repository.fetchSets(containing: word.id).count, 2)
    }

    func testRejectsCrossLanguageCategoryAndSetMembership() throws {
        let database = try DatabaseManager.inMemory()
        let repository = LibraryRepository(database: database)
        let chinese = try repository.createLanguage(name: "Chinese")
        let english = try repository.createLanguage(name: "English")
        let category = try repository.createCategory(languageID: chinese.id, name: "Food")
        let englishSet = try repository.createSet(languageID: english.id, name: "Food")

        XCTAssertThrowsError(try repository.createSet(
            languageID: english.id,
            name: "Invalid",
            categoryID: category.id
        )) { error in
            XCTAssertEqual(error as? LibraryRepositoryError, .categoryLanguageMismatch)
        }

        let chineseWord = try repository.createWord(
            languageID: chinese.id,
            text: "你好",
            translation: "hello"
        )
        XCTAssertThrowsError(try repository.addWord(chineseWord.id, toSet: englishSet.id)) { error in
            XCTAssertEqual(error as? LibraryRepositoryError, .setLanguageMismatch)
        }
    }

    func testDatabaseSurvivesReopening() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("library.sqlite")
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }

        let languageID: String
        do {
            let database = try DatabaseManager(path: url.path)
            let repository = LibraryRepository(database: database)
            languageID = try repository.createLanguage(name: "Japanese", code: "ja").id
        }

        let reopened = try DatabaseManager(path: url.path)
        let languages = try LibraryRepository(database: reopened).fetchLanguages()
        XCTAssertEqual(languages.map(\.id), [languageID])
    }
}
