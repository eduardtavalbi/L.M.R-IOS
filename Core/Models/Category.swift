import Foundation
import GRDB

struct Category: Codable, FetchableRecord, MutablePersistableRecord, Identifiable, Equatable {
    static let databaseTableName = "categories"

    var id: String
    var languageID: String
    var parentID: String?
    var name: String
    var createdAt: Date

    init(
        id: String = UUID().uuidString,
        languageID: String,
        parentID: String? = nil,
        name: String,
        createdAt: Date = .now
    ) {
        self.id = id
        self.languageID = languageID
        self.parentID = parentID
        self.name = name
        self.createdAt = createdAt
    }
}

enum CategoryHierarchy {
    /// Returns a readable category path from the root to the supplied category.
    static func path(for category: Category, in categories: [Category]) -> String {
        let categoriesByID = Dictionary(categories.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        var names = [category.name]
        var visited: Set<String> = [category.id]
        var parentID = category.parentID

        while let id = parentID, visited.insert(id).inserted, let parent = categoriesByID[id] {
            names.append(parent.name)
            parentID = parent.parentID
        }

        return names.reversed().joined(separator: " / ")
    }
}
