import Foundation
import GRDB

struct VocabularySet: Codable, FetchableRecord, MutablePersistableRecord, Identifiable, Equatable {
    var id: String
    var languageID: String
    var categoryID: String?
    var name: String
    var details: String?
    var createdAt: Date
    var updatedAt: Date

    init(
        id: String = UUID().uuidString,
        languageID: String,
        categoryID: String? = nil,
        name: String,
        details: String? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.languageID = languageID
        self.categoryID = categoryID
        self.name = name
        self.details = details
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
