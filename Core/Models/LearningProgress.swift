import Foundation
import GRDB

struct LearningProgress: Codable, FetchableRecord, MutablePersistableRecord, Identifiable, Equatable {
    static let databaseTableName = "learningProgress"

    var wordID: String
    var repetitions: Int
    var correctAnswers: Int
    var incorrectAnswers: Int
    var streak: Int
    var intervalDays: Int
    var easeFactor: Double
    var dueAt: Date?
    var lastReviewedAt: Date?
    var updatedAt: Date

    var id: String { wordID }

    init(
        wordID: String,
        repetitions: Int = 0,
        correctAnswers: Int = 0,
        incorrectAnswers: Int = 0,
        streak: Int = 0,
        intervalDays: Int = 0,
        easeFactor: Double = 2.5,
        dueAt: Date? = nil,
        lastReviewedAt: Date? = nil,
        updatedAt: Date = .now
    ) {
        self.wordID = wordID
        self.repetitions = repetitions
        self.correctAnswers = correctAnswers
        self.incorrectAnswers = incorrectAnswers
        self.streak = streak
        self.intervalDays = intervalDays
        self.easeFactor = easeFactor
        self.dueAt = dueAt
        self.lastReviewedAt = lastReviewedAt
        self.updatedAt = updatedAt
    }
}


enum WordLearningStatus: Equatable {
    case new
    case learning
    case mastered
}

extension LearningProgress {
    var status: WordLearningStatus {
        guard lastReviewedAt != nil else { return .new }
        return intervalDays >= 7 && streak >= 3 ? .mastered : .learning
    }
}
