import Foundation
import GRDB

enum DatabaseError: Error {
    case applicationSupportUnavailable
}

final class DatabaseManager {
    let dbQueue: DatabaseQueue

    init(path: String) throws {
        var configuration = Configuration()
        configuration.foreignKeysEnabled = true
        configuration.label = "com.eduardtavalbi.lmr.database"
        dbQueue = try DatabaseQueue(path: path, configuration: configuration)
        try Self.migrator.migrate(dbQueue)
    }

    convenience init() throws {
        guard let directory = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first else {
            throw DatabaseError.applicationSupportUnavailable
        }

        let appDirectory = directory.appendingPathComponent("LMR", isDirectory: true)
        try FileManager.default.createDirectory(
            at: appDirectory,
            withIntermediateDirectories: true
        )
        let databaseURL = appDirectory.appendingPathComponent("library.sqlite")
        try self.init(path: databaseURL.path)
    }

    static func inMemory() throws -> DatabaseManager {
        try DatabaseManager(path: ":memory:")
    }

    private static var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()

        migrator.registerMigration("v1_create_library") { db in
            try db.create(table: "languages") { table in
                table.column("id", .text).primaryKey()
                table.column("name", .text).notNull()
                table.column("code", .text)
                table.column("createdAt", .datetime).notNull()
            }

            try db.create(table: "categories") { table in
                table.column("id", .text).primaryKey()
                table.column("languageID", .text).notNull()
                    .references("languages", onDelete: .cascade)
                table.column("parentID", .text)
                    .references("categories", onDelete: .cascade)
                table.column("name", .text).notNull()
                table.column("createdAt", .datetime).notNull()
            }
            try db.create(index: "categories_language_parent", on: "categories", columns: ["languageID", "parentID"])

            try db.create(table: "vocabularySets") { table in
                table.column("id", .text).primaryKey()
                table.column("languageID", .text).notNull()
                    .references("languages", onDelete: .cascade)
                table.column("categoryID", .text)
                    .references("categories", onDelete: .setNull)
                table.column("name", .text).notNull()
                table.column("details", .text)
                table.column("createdAt", .datetime).notNull()
                table.column("updatedAt", .datetime).notNull()
            }
            try db.create(index: "sets_language", on: "vocabularySets", columns: ["languageID"])
            try db.create(index: "sets_category", on: "vocabularySets", columns: ["categoryID"])

            try db.create(table: "words") { table in
                table.column("id", .text).primaryKey()
                table.column("languageID", .text).notNull()
                    .references("languages", onDelete: .cascade)
                table.column("text", .text).notNull()
                table.column("translation", .text).notNull()
                table.column("transcription", .text)
                table.column("notes", .text)
                table.column("example", .text)
                table.column("createdAt", .datetime).notNull()
                table.column("updatedAt", .datetime).notNull()
            }
            try db.create(index: "words_language_text", on: "words", columns: ["languageID", "text"])
            try db.create(index: "words_translation", on: "words", columns: ["translation"])

            try db.create(table: "set_words") { table in
                table.column("setID", .text).notNull()
                    .references("vocabularySets", onDelete: .cascade)
                table.column("wordID", .text).notNull()
                    .references("words", onDelete: .cascade)
                table.primaryKey(["setID", "wordID"])
            }
            try db.create(index: "set_words_word", on: "set_words", columns: ["wordID"])

            try db.create(table: "learningProgress") { table in
                table.column("wordID", .text).primaryKey()
                    .references("words", onDelete: .cascade)
                table.column("repetitions", .integer).notNull().defaults(to: 0)
                table.column("correctAnswers", .integer).notNull().defaults(to: 0)
                table.column("incorrectAnswers", .integer).notNull().defaults(to: 0)
                table.column("streak", .integer).notNull().defaults(to: 0)
                table.column("intervalDays", .integer).notNull().defaults(to: 0)
                table.column("easeFactor", .double).notNull().defaults(to: 2.5)
                table.column("dueAt", .datetime)
                table.column("lastReviewedAt", .datetime)
                table.column("updatedAt", .datetime).notNull()
            }
            try db.create(index: "progress_due", on: "learningProgress", columns: ["dueAt"])
        }

        return migrator
    }
}
