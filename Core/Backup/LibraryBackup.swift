import Foundation

struct LibraryBackup: Codable, Equatable {
    static let currentVersion = 1

    var formatVersion: Int
    var exportedAt: Date
    var languages: [Language]
    var categories: [Category]
    var sets: [VocabularySet]
    var words: [Word]
    var memberships: [LibraryBackupMembership]
    var learningProgress: [LearningProgress]
    var studyActivity: [StudyActivity]

    init(
        formatVersion: Int = currentVersion,
        exportedAt: Date = .now,
        languages: [Language],
        categories: [Category],
        sets: [VocabularySet],
        words: [Word],
        memberships: [LibraryBackupMembership],
        learningProgress: [LearningProgress],
        studyActivity: [StudyActivity]
    ) {
        self.formatVersion = formatVersion
        self.exportedAt = exportedAt
        self.languages = languages
        self.categories = categories
        self.sets = sets
        self.words = words
        self.memberships = memberships
        self.learningProgress = learningProgress
        self.studyActivity = studyActivity
    }

    func encoded() throws -> Data {
        try validate()
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(self)
    }

    static func decode(_ data: Data) throws -> LibraryBackup {
        let backup = try JSONDecoder().decode(LibraryBackup.self, from: data)
        try backup.validate()
        return backup
    }

    func validate() throws {
        guard formatVersion == Self.currentVersion else { throw LibraryBackupError.unsupportedVersion }
        guard Self.hasUniqueIDs(languages.map(\.id)),
              Self.hasUniqueIDs(categories.map(\.id)),
              Self.hasUniqueIDs(sets.map(\.id)),
              Self.hasUniqueIDs(words.map(\.id)),
              Self.hasUniqueIDs(learningProgress.map(\.wordID)),
              Self.hasUniqueIDs(studyActivity.map(\.day)) else {
            throw LibraryBackupError.duplicateIdentifiers
        }

        let languageIDs = Set(languages.map(\.id))
        let categoryByID = Dictionary(uniqueKeysWithValues: categories.map { ($0.id, $0) })
        let setByID = Dictionary(uniqueKeysWithValues: sets.map { ($0.id, $0) })
        let wordByID = Dictionary(uniqueKeysWithValues: words.map { ($0.id, $0) })

        for category in categories {
            guard languageIDs.contains(category.languageID) else { throw LibraryBackupError.invalidRelationships }
            if let parentID = category.parentID {
                guard let parent = categoryByID[parentID],
                      parent.languageID == category.languageID,
                      parentID != category.id else { throw LibraryBackupError.invalidRelationships }
            }
        }
        for category in categories {
            var visited = Set<String>()
            var cursor: Category? = category
            while let current = cursor {
                guard visited.insert(current.id).inserted else { throw LibraryBackupError.invalidRelationships }
                cursor = current.parentID.flatMap { categoryByID[$0] }
            }
        }
        for set in sets {
            guard languageIDs.contains(set.languageID) else { throw LibraryBackupError.invalidRelationships }
            if let categoryID = set.categoryID {
                guard categoryByID[categoryID]?.languageID == set.languageID else {
                    throw LibraryBackupError.invalidRelationships
                }
            }
        }
        for word in words {
            guard languageIDs.contains(word.languageID) else { throw LibraryBackupError.invalidRelationships }
        }
        for membership in memberships {
            guard let set = setByID[membership.setID],
                  let word = wordByID[membership.wordID],
                  set.languageID == word.languageID else { throw LibraryBackupError.invalidRelationships }
        }
        for progress in learningProgress where wordByID[progress.wordID] == nil {
            throw LibraryBackupError.invalidRelationships
        }
    }

    private static func hasUniqueIDs(_ ids: [String]) -> Bool {
        Set(ids).count == ids.count
    }
}

struct LibraryBackupMembership: Codable, Equatable {
    var setID: String
    var wordID: String
}

enum LibraryBackupError: Error, Equatable {
    case unsupportedVersion
    case duplicateIdentifiers
    case invalidRelationships
}
