import Foundation

enum SpacedRepetitionScheduler {
    static func applying(knewAnswer: Bool, to current: LearningProgress, reviewedAt: Date = .now) -> LearningProgress {
        var progress = current
        progress.lastReviewedAt = reviewedAt
        progress.updatedAt = reviewedAt
        if knewAnswer {
            progress.correctAnswers += 1
            progress.repetitions += 1
            progress.streak += 1
            progress.easeFactor = min(3.0, max(1.3, progress.easeFactor + 0.1))
            switch progress.streak {
            case 1: progress.intervalDays = 1
            case 2: progress.intervalDays = 3
            default:
                progress.intervalDays = max(1, Int((Double(max(progress.intervalDays, 1)) * progress.easeFactor).rounded()))
            }
            progress.dueAt = Calendar.current.date(byAdding: .day, value: progress.intervalDays, to: reviewedAt)
        } else {
            progress.incorrectAnswers += 1
            progress.repetitions = 0
            progress.streak = 0
            progress.intervalDays = 0
            progress.easeFactor = max(1.3, progress.easeFactor - 0.2)
            progress.dueAt = reviewedAt.addingTimeInterval(600)
        }
        return progress
    }
}
