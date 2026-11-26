import Foundation
import SwiftUI

@MainActor
final class LibraryStore: ObservableObject {
    @Published private(set) var languages: [Language] = []
    @Published var lastError: String?
    private let database: DatabaseManager?
    private let repository: LibraryRepository?

    init() {
        do {
            let database = try DatabaseManager()
            self.database = database
            self.repository = LibraryRepository(database: database)
            refreshLanguages()
        } catch {
            self.database = nil
            self.repository = nil
            self.lastError = error.localizedDescription
        }
    }

    func refreshLanguages() {
        do {
            languages = try repository?.fetchLanguages() ?? []
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
    }

    func language(id: String) -> Language? { languages.first { $0.id == id } }

    func search(query: String) -> LibrarySearchResults {
        do {
            return try repository?.searchLibrary(query)
                ?? LibrarySearchResults(words: [], sets: [], categories: [])
        } catch {
            lastError = error.localizedDescription
            return LibrarySearchResults(words: [], sets: [], categories: [])
        }
    }

    func categories(languageID: String, parentID: String? = nil) -> [Category] {
        do {
            return try repository?.fetchCategories(languageID: languageID).filter { $0.parentID == parentID } ?? []
        } catch {
            lastError = error.localizedDescription
            return []
        }
    }

    func sets(languageID: String, categoryID: String? = nil) -> [VocabularySet] {
        do {
            return try repository?.fetchSets(languageID: languageID, categoryID: categoryID) ?? []
        } catch {
            lastError = error.localizedDescription
            return []
        }
    }

    func allSets(languageID: String) -> [VocabularySet] {
        do { return try repository?.fetchAllSets(languageID: languageID) ?? [] }
        catch { lastError = error.localizedDescription; return [] }
    }

    func learningWords(setID: String, dueAt: Date = .now) -> [Word] {
        do { return try repository?.fetchLearningQueue(inSet: setID, dueAt: dueAt) ?? [] }
        catch { lastError = error.localizedDescription; return [] }
    }

    func dueWordCount(setID: String, dueAt: Date = .now) -> Int {
        learningWords(setID: setID, dueAt: dueAt).count
    }

    func learningWords(setIDs: [String], dueAt: Date = .now) -> [Word] {
        do { return try repository?.fetchLearningQueue(inSets: setIDs, dueAt: dueAt) ?? [] }
        catch { lastError = error.localizedDescription; return [] }
    }

    func weakWords(setIDs: [String]) -> [Word] {
        do { return try repository?.fetchWeakWords(inSets: setIDs) ?? [] }
        catch { lastError = error.localizedDescription; return [] }
    }

    func words(setIDs: [String]) -> [Word] {
        var seen = Set<String>()
        return Set(setIDs).sorted().flatMap { words(setID: $0) }.filter { seen.insert($0.id).inserted }
    }
    func recordLearningAnswer(wordID: String, knewAnswer: Bool) throws {
        guard let repository else { throw StoreError.databaseUnavailable }
        try repository.recordLearningAnswer(wordID: wordID, knewAnswer: knewAnswer)
        objectWillChange.send()
    }

    func words(setID: String) -> [Word] {
        do {
            return try repository?.fetchWords(inSet: setID) ?? []
        } catch {
            lastError = error.localizedDescription
            return []
        }
    }

    func createLanguage(name: String, code: String?) throws {
        guard let repository else { throw StoreError.databaseUnavailable }
        try repository.createLanguage(name: name, code: code)
        refreshLanguages()
    }

    func createCategory(languageID: String, name: String, parentID: String?) throws {
        guard let repository else { throw StoreError.databaseUnavailable }
        try repository.createCategory(languageID: languageID, name: name, parentID: parentID)
        objectWillChange.send()
    }

    func createSet(languageID: String, name: String, categoryID: String?) throws {
        guard let repository else { throw StoreError.databaseUnavailable }
        try repository.createSet(languageID: languageID, name: name, categoryID: categoryID)
        objectWillChange.send()
    }

    func moveSet(_ setID: String, to categoryID: String?) throws {
        guard let repository else { throw StoreError.databaseUnavailable }
        try repository.moveSet(setID, toCategory: categoryID)
        objectWillChange.send()
    }

    func duplicateWord(languageID: String, text: String, translation: String) -> Word? {
        do {
            return try repository?.findDuplicateWord(languageID: languageID, text: text, translation: translation)
        } catch {
            lastError = error.localizedDescription
            return nil
        }
    }

    func addWord(_ wordID: String, toSet setID: String) throws {
        guard let repository else { throw StoreError.databaseUnavailable }
        try repository.addWord(wordID, toSet: setID)
        objectWillChange.send()
    }

    func createWord(languageID: String, setID: String, text: String, translation: String, transcription: String?) throws {
        guard let repository else { throw StoreError.databaseUnavailable }
        try repository.createWord(
            languageID: languageID,
            text: text,
            translation: translation,
            transcription: transcription,
            inSet: setID
        )
        objectWillChange.send()
    }


    func updateLanguage(_ id: String, name: String, code: String?) throws {
        guard let repository else { throw StoreError.databaseUnavailable }
        try repository.updateLanguage(id, name: name, code: code)
        refreshLanguages()
    }

    func updateCategory(_ id: String, name: String) throws {
        guard let repository else { throw StoreError.databaseUnavailable }
        try repository.updateCategory(id, name: name)
        objectWillChange.send()
    }

    func updateSet(_ id: String, name: String, details: String? = nil) throws {
        guard let repository else { throw StoreError.databaseUnavailable }
        try repository.updateSet(id, name: name, details: details)
        objectWillChange.send()
    }

    func updateWord(_ id: String, text: String, translation: String, transcription: String?) throws {
        guard let repository else { throw StoreError.databaseUnavailable }
        try repository.updateWord(id, text: text, translation: translation, transcription: transcription)
        objectWillChange.send()
    }

    func deleteLanguage(_ id: String) throws {
        guard let repository else { throw StoreError.databaseUnavailable }
        try repository.deleteLanguage(id)
        refreshLanguages()
    }

    func deleteCategory(_ id: String) throws {
        guard let repository else { throw StoreError.databaseUnavailable }
        try repository.deleteCategory(id)
        objectWillChange.send()
    }

    func deleteSet(_ id: String) throws {
        guard let repository else { throw StoreError.databaseUnavailable }
        try repository.deleteSet(id)
        objectWillChange.send()
    }

    func deleteWord(_ id: String) throws {
        guard let repository else { throw StoreError.databaseUnavailable }
        try repository.deleteWord(id)
        objectWillChange.send()
    }

    enum StoreError: LocalizedError {
        case databaseUnavailable
        var errorDescription: String? { "Не удалось открыть локальную базу данных." }
    }
}
