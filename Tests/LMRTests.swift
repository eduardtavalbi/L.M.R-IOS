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
        let child = try repository.createCategory(languageID: language.id, name: "Fruit", parentID: parent.id)
        let fetched = try repository.fetchCategories(languageID: language.id)
        XCTAssertEqual(fetched.map(\.id), [parent.id, child.id])
        XCTAssertEqual(fetched.map(\.name), ["Food", "Fruit"])
        XCTAssertNil(fetched[0].parentID)
        XCTAssertEqual(fetched[1].parentID, parent.id)
        XCTAssertTrue(fetched.allSatisfy { $0.languageID == language.id })
    }

    func testUncategorizedSetAndMovingBetweenCategories() throws {
        let database = try DatabaseManager.inMemory()
        let repository = LibraryRepository(database: database)
        let language = try repository.createLanguage(name: "English")
        let first = try repository.createCategory(languageID: language.id, name: "Travel")
        let second = try repository.createCategory(languageID: language.id, name: "Work")
        let set = try repository.createSet(languageID: language.id, name: "Phrases")
        let uncategorized = try repository.fetchSets(languageID: language.id)
        XCTAssertEqual(uncategorized.map(\.id), [set.id])
        XCTAssertNil(uncategorized.first?.categoryID)
        try repository.moveSet(set.id, toCategory: first.id)
        let inFirst = try repository.fetchSets(languageID: language.id, categoryID: first.id)
        XCTAssertEqual(inFirst.first?.id, set.id)
        XCTAssertEqual(inFirst.first?.categoryID, first.id)
        try repository.moveSet(set.id, toCategory: second.id)
        let inSecond = try repository.fetchSets(languageID: language.id, categoryID: second.id)
        XCTAssertEqual(inSecond.first?.id, set.id)
        XCTAssertEqual(inSecond.first?.categoryID, second.id)
    }

    func testWordCanBelongToMultipleSetsAndSharesProgress() throws {
        let database = try DatabaseManager.inMemory()
        let repository = LibraryRepository(database: database)
        let language = try repository.createLanguage(name: "Chinese", code: "zh")
        let firstSet = try repository.createSet(languageID: language.id, name: "Food")
        let secondSet = try repository.createSet(languageID: language.id, name: "Daily")
        let word = try repository.createWord(languageID: language.id, text: "苹果", translation: "яблоко", transcription: "píngguǒ", inSet: firstSet.id)
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
        XCTAssertThrowsError(try repository.createSet(languageID: english.id, name: "Invalid", categoryID: category.id)) { error in
            XCTAssertEqual(error as? LibraryRepositoryError, .categoryLanguageMismatch)
        }
        let chineseWord = try repository.createWord(languageID: chinese.id, text: "你好", translation: "hello")
        XCTAssertThrowsError(try repository.addWord(chineseWord.id, toSet: englishSet.id)) { error in
            XCTAssertEqual(error as? LibraryRepositoryError, .setLanguageMismatch)
        }
    }

    func testDatabaseSurvivesReopening() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("library.sqlite")
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
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

    func testGlobalSearchFindsWordsTranslationsSetsAndCategories() throws {
        let database = try DatabaseManager.inMemory()
        let repository = LibraryRepository(database: database)
        let language = try repository.createLanguage(name: "Chinese", code: "zh")
        let category = try repository.createCategory(languageID: language.id, name: "Food and drinks")
        let foodSet = try repository.createSet(languageID: language.id, name: "Breakfast", categoryID: category.id)
        let dailySet = try repository.createSet(languageID: language.id, name: "Daily phrases")
        let word = try repository.createWord(
            languageID: language.id,
            text: "苹果",
            translation: "green apple",
            transcription: "píngguǒ",
            inSet: foodSet.id
        )
        try repository.addWord(word.id, toSet: dailySet.id)

        let byOriginal = try repository.searchLibrary("苹果")
        XCTAssertEqual(byOriginal.words.map(\.word.id), [word.id])
        XCTAssertEqual(Set(byOriginal.words[0].sets.map(\.id)), Set([foodSet.id, dailySet.id]))
        let byTranslation = try repository.searchLibrary("GREEN")
        XCTAssertEqual(byTranslation.words.map(\.word.id), [word.id])
        let bySetName = try repository.searchLibrary("break")
        XCTAssertEqual(bySetName.sets.map(\.id), [foodSet.id])
        let byCategoryName = try repository.searchLibrary("drinks")
        XCTAssertEqual(byCategoryName.categories.map(\.id), [category.id])
        XCTAssertTrue(try repository.searchLibrary("   ").isEmpty)
    }

    func testLibraryEntitiesCanBeEdited() throws {
        let repository = LibraryRepository(database: try DatabaseManager.inMemory())
        let language = try repository.createLanguage(name: "Chinese", code: "zh")
        let category = try repository.createCategory(languageID: language.id, name: "Food")
        let set = try repository.createSet(languageID: language.id, name: "Breakfast", categoryID: category.id)
        let word = try repository.createWord(languageID: language.id, text: "苹果", translation: "apple", inSet: set.id)

        try repository.updateLanguage(language.id, name: "Mandarin", code: "cmn")
        try repository.updateCategory(category.id, name: "Meals")
        try repository.updateSet(set.id, name: "Morning food", details: "Useful words")
        try repository.updateWord(word.id, text: "香蕉", translation: "banana", transcription: "xiāngjiāo")

        XCTAssertEqual(try repository.fetchLanguage(id: language.id)?.name, "Mandarin")
        XCTAssertEqual(try repository.fetchLanguage(id: language.id)?.code, "cmn")
        XCTAssertEqual(try repository.fetchCategories(languageID: language.id).first?.name, "Meals")
        XCTAssertEqual(try repository.fetchSets(languageID: language.id, categoryID: category.id).first?.name, "Morning food")
        let updatedWord = try repository.fetchWords(inSet: set.id).first
        XCTAssertEqual(updatedWord?.text, "香蕉")
        XCTAssertEqual(updatedWord?.translation, "banana")
        XCTAssertEqual(updatedWord?.transcription, "xiāngjiāo")
        XCTAssertEqual(try repository.fetchProgress(for: word.id)?.wordID, word.id)
    }

    func testDeletingCategoryPreservesSetsAndDeletingSetPreservesSharedWords() throws {
        let repository = LibraryRepository(database: try DatabaseManager.inMemory())
        let language = try repository.createLanguage(name: "English")
        let category = try repository.createCategory(languageID: language.id, name: "Work")
        let set = try repository.createSet(languageID: language.id, name: "Meetings", categoryID: category.id)
        let otherSet = try repository.createSet(languageID: language.id, name: "Daily")
        let word = try repository.createWord(languageID: language.id, text: "hello", translation: "привет", inSet: set.id)
        try repository.addWord(word.id, toSet: otherSet.id)

        try repository.deleteCategory(category.id)
        XCTAssertTrue(try repository.fetchCategories(languageID: language.id).isEmpty)
        XCTAssertNil(try repository.fetchSets(languageID: language.id, categoryID: set.categoryID).first)
        XCTAssertEqual(try repository.fetchSets(languageID: language.id).map(\.id), [set.id, otherSet.id].sorted { $0 < $1 }.filter { $0 == set.id || $0 == otherSet.id }.sorted { $0 == set.id ? true : $1 == set.id ? false : $0 < $1 })
        XCTAssertNil(try repository.fetchSets(containing: word.id).first(where: { $0.id == set.id })?.categoryID)

        try repository.deleteSet(set.id)
        XCTAssertEqual(try repository.fetchWords(inSet: otherSet.id).map(\.id), [word.id])
        XCTAssertEqual(try repository.fetchProgress(for: word.id)?.wordID, word.id)
    }

    func testDeletingWordRemovesMembershipAndProgressButDeletingLanguageCascades() throws {
        let repository = LibraryRepository(database: try DatabaseManager.inMemory())
        let language = try repository.createLanguage(name: "Japanese")
        let set = try repository.createSet(languageID: language.id, name: "Basics")
        let word = try repository.createWord(languageID: language.id, text: "水", translation: "вода", inSet: set.id)
        try repository.deleteWord(word.id)
        XCTAssertTrue(try repository.fetchWords(inSet: set.id).isEmpty)
        XCTAssertNil(try repository.fetchProgress(for: word.id))

        let anotherWord = try repository.createWord(languageID: language.id, text: "火", translation: "огонь", inSet: set.id)
        try repository.deleteLanguage(language.id)
        XCTAssertNil(try repository.fetchLanguage(id: language.id))
        XCTAssertTrue(try repository.fetchWords(inSet: set.id).isEmpty)
        XCTAssertNil(try repository.fetchProgress(for: anotherWord.id))
    }

}
