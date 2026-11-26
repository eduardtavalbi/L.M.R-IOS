import Foundation
import GRDB

struct Word: Codable, FetchableRecord, MutablePersistableRecord, Identifiable, Equatable {
    var id: String
    var languageID: String
    var text: String
    var translation: String
    var transcription: String?
    var notes: String?
    var example: String?
    var createdAt: Date
    var updatedAt: Date

    init(
        id: String = UUID().uuidString,
        languageID: String,
        text: String,
        translation: String,
        transcription: String? = nil,
        notes: String? = nil,
        example: String? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.languageID = languageID
        self.text = text
        self.translation = translation
        self.transcription = transcription
        self.notes = notes
        self.example = example
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
