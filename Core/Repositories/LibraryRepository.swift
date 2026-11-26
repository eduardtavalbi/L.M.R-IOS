import Foundation
import GRDB

enum LibraryRepositoryError: Error, Equatable {
    case emptyName
    case emptyWord
    case emptyTranslation
    case languageNotFound
    case categoryNotFound
    case parentCategoryLanguageMismatch
    case categoryLanguageMismatch
    case setNotFound
    case wordNotFound
    case wordLanguageMismatch
    case setLanguageMismatch
}

final class LibraryRepository {
    private let database: DatabaseManager

    init(database: DatabaseManager) {
        self.database = database
    }

    @discardableResult
    func createLanguage(name: String, code: String? = nil) throws -> Language {
        let normalizedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedName.isEmpty else { throw LibraryRepositoryError.emptyName }
        let language = Language(name: normalizedName, code: code)
        try database.dbQueue.write { db in try language.insert(db) }
        return language
    }

    @discardableResult
    func createCategory(
        languageID: String,
        name: String,
        parentID: String? = nil
    ) throws -> Category {
        let normalizedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedName.isEmpty else { throw LibraryRepositoryError.emptyName }

        return try database.dbQueue.write { db in
            guard try Language.fetchOne(db, key: languageID) != nil else {
                throw LibraryRepositoryError.languageNotFound
            }
            if let parentID {
                guard let parent = try Category.fetchOne(db, key: parentID) else {
                    throw LibraryRepositoryError.categoryNotFound
                }
                guard parent.languageID == languageID else {
                    throw LibraryRepositoryError.parentCategoryLanguageMismatch
                }
            }
            let category = Category(languageID: languageID, parentID: parentID, name: normalizedName)
            try category.insert(db)
            return category
        }
    }

    @discardableResult
    func createSet(
        languageID: String,
        name: String,
        categoryID: String? = nil,
        details: String? = nil
    ) throws -> VocabularySet {
        let normalizedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedName.isEmpty else { throw LibraryRepositoryError.emptyName }

        return try database.dbQueue.write { db in
            guard try Language.fetchOne(db, key: languageID) != nil else {
                throw LibraryRepositoryError.languageNotFound
            }
            if let categoryID {
                guard let category = try Category.fetchOne(db, key: categoryID) else {
                    throw LibraryRepositoryError.categoryNotFound
                }
                guard category.languageID == languageID else {
                    throw LibraryRepositoryError.categoryLanguageMismatch
                }
            }
            let set = VocabularySet(
                languageID: languageID,
                categoryID: categoryID,
                name: normalizedName,
                details: details
            )
            try set.insert(db)
            return set
        }
    }

    @discardableResult
    func createWord(
        languageID: String,
        text: String,
        translation: String,
        transcription: String? = nil,
        notes: String? = nil,
        example: String? = nil,
        inSet setID: String? = nil
    ) throws -> Word {
        let normalizedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedTranslation = translation.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedText.isEmpty else { throw LibraryRepositoryError.emptyWord }
        guard !normalizedTranslation.isEmpty else { throw LibraryRepositoryError.emptyTranslation }

        return try database.dbQueue.write { db in
            guard try Language.fetchOne(db, key: languageID) != nil else {
                throw LibraryRepositoryError.languageNotFound
            }
            if let setID {
                guard let set = try VocabularySet.fetchOne(db, key: setID) else {
                    throw LibraryRepositoryError.setNotFound
                }
                guard set.languageID == languageID else {
                    throw LibraryRepositoryError.setLanguageMismatch
                }
            }

            let word = Word(
                languageID: languageID,
                text: normalizedText,
                translation: normalizedTranslation,
                transcription: transcription,
                notes: notes,
                example: example
            )
            try word.insert(db)
            try LearningProgress(wordID: word.id).insert(db)
            if let setID {
                try db.execute(
                    sql: "INSERT INTO set_words (setID, wordID) VALUES (?, ?)",
                    arguments: [setID, word.id]
                )
            }
            return word
        }
    }

    func addWord(_ wordID: String, toSet setID: String) throws {
        try database.dbQueue.write { db in
            guard let word = try Word.fetchOne(db, key: wordID) else {
                throw LibraryRepositoryError.wordNotFound
            }
            guard let set = try VocabularySet.fetchOne(db, key: setID) else {
                throw LibraryRepositoryError.setNotFound
            }
            guard word.languageID == set.languageID else {
                throw LibraryRepositoryError.setLanguageMismatch
            }
            try db.execute(
                sql: "INSERT OR IGNORE INTO set_words (setID, wordID) VALUES (?, ?)",
                arguments: [setID, wordID]
            )
        }
    }

    func moveSet(_ setID: String, toCategory categoryID: String?) throws {
        try database.dbQueue.write { db in
            guard var set = try VocabularySet.fetchOne(db, key: setID) else {
                throw LibraryRepositoryError.setNotFound
            }
            if let categoryID {
                guard let category = try Category.fetchOne(db, key: categoryID) else {
                    throw LibraryRepositoryError.categoryNotFound
                }
                guard category.languageID == set.languageID else {
                    throw LibraryRepositoryError.categoryLanguageMismatch
                }
            }
            set.categoryID = categoryID
            set.updatedAt = .now
            try set.update(db)
        }
    }

    func fetchLanguages() throws -> [Language] {
        try database.dbQueue.read { db in
            try Language.order(Column("name").collating(.localizedCaseInsensitiveCompare)).fetchAll(db)
        }
    }

    func fetchCategories(languageID: String) throws -> [Category] {
        try database.dbQueue.read { db in
            try Category.filter(Column("languageID") == languageID)
                .order(Column("name").collating(.localizedCaseInsensitiveCompare))
                .fetchAll(db)
        }
    }

    func fetchSets(languageID: String, categoryID: String? = nil) throws -> [VocabularySet] {
        try database.dbQueue.read { db in
            var request = VocabularySet.filter(Column("languageID") == languageID)
            if let categoryID {
                request = request.filter(Column("categoryID") == categoryID)
            } else {
                request = request.filter(Column("categoryID") == nil)
            }
            return try request.order(Column("name")).fetchAll(db)
        }
    }

    func fetchWords(inSet setID: String) throws -> [Word] {
        try database.dbQueue.read { db in
            try Word
                .joining(
                    required: SQLRelation(
                        to: "set_words",
                        condition: ForeignKey(["id"], to: ["wordID"])
                    )
                )
                .filter(Column("setID") == setID)
                .order(Column("text"))
                .fetchAll(db)
        }
    }

    func fetchProgress(for wordID: String) throws -> LearningProgress? {
        try database.dbQueue.read { db in
            try LearningProgress.fetchOne(db, key: wordID)
        }
    }

    func fetchSets(containing wordID: String) throws -> [VocabularySet] {
        try database.dbQueue.read { db in
            try VocabularySet
                .joining(
                    required: SQLRelation(
                        to: "set_words",
                        condition: ForeignKey(["id"], to: ["setID"])
                    )
                )
                .filter(Column("wordID") == wordID)
                .order(Column("name"))
                .fetchAll(db)
        }
    }
}
