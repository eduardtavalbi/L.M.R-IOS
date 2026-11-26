import Foundation
import GRDB

struct Language: Codable, FetchableRecord, MutablePersistableRecord, Identifiable, Equatable {
    var id: String
    var name: String
    var code: String?
    var createdAt: Date

    init(id: String = UUID().uuidString, name: String, code: String? = nil, createdAt: Date = .now) {
        self.id = id
        self.name = name
        self.code = code
        self.createdAt = createdAt
    }
}
