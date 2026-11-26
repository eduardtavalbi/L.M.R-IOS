import Foundation
import GRDB

struct Category: Codable, FetchableRecord, MutablePersistableRecord, Identifiable, Equatable {
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
