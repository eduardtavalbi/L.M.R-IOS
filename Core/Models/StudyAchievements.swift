import Foundation

struct StudyAchievement: Identifiable, Equatable {
    let id: String
    let title: String
    let detail: String
    let symbol: String
    let progress: Int
    let goal: Int

    var isUnlocked: Bool { progress >= goal }
    var progressFraction: Double { min(Double(progress) / Double(goal), 1) }

    static func all(for stats: LearningStatistics) -> [StudyAchievement] {
        [
            StudyAchievement(id: "first_word", title: "Первое слово", detail: "Добавь первое слово в словарь", symbol: "character.book.closed.fill", progress: stats.totalWords, goal: 1),
            StudyAchievement(id: "word_collector", title: "Коллекционер", detail: "Собери 50 слов", symbol: "books.vertical.fill", progress: stats.totalWords, goal: 50),
            StudyAchievement(id: "hundred_words", title: "Сотня слов", detail: "Добавь 100 слов", symbol: "text.book.closed.fill", progress: stats.totalWords, goal: 100),
            StudyAchievement(id: "first_mastered", title: "Первое освоенное", detail: "Освой первое слово", symbol: "checkmark.seal.fill", progress: stats.masteredWords, goal: 1),
            StudyAchievement(id: "memory_master", title: "Тренировка памяти", detail: "Освой 25 слов", symbol: "brain.head.profile", progress: stats.masteredWords, goal: 25),
            StudyAchievement(id: "seven_day_streak", title: "Неделя в ритме", detail: "Занимайся 7 дней подряд", symbol: "flame.fill", progress: stats.currentStreak, goal: 7),
            StudyAchievement(id: "hundred_reviews", title: "Сто повторений", detail: "Повтори слова 100 раз", symbol: "arrow.2.circlepath", progress: stats.totalReviews, goal: 100)
        ]
    }
}
