import Foundation
import SwiftUI
import GRDB

struct StudyActivity: Codable, FetchableRecord, MutablePersistableRecord, Identifiable, Equatable {
    static let databaseTableName = "studyActivity"
    var day: String
    var reviewCount: Int
    var correctCount: Int
    var incorrectCount: Int
    var newWordsCount: Int
    var id: String { day }

    static func dayKey(for date: Date, calendar: Calendar = .current) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }
}

struct LearningStatistics: Equatable {
    var totalWords: Int
    var masteredWords: Int
    var totalReviews: Int
    var correctAnswers: Int
    var incorrectAnswers: Int
    var studyDays: Int
    var currentStreak: Int
    var activity: [StudyActivity]

    var accuracy: Int {
        let total = correctAnswers + incorrectAnswers
        return total == 0 ? 0 : Int((Double(correctAnswers) / Double(total) * 100).rounded())
    }

    static let empty = LearningStatistics(totalWords: 0, masteredWords: 0, totalReviews: 0, correctAnswers: 0, incorrectAnswers: 0, studyDays: 0, currentStreak: 0, activity: [])
}

struct ProfileView: View {
    @ObservedObject var store: LibraryStore
    @State private var displayedMonth = Calendar.current.dateInterval(of: .month, for: .now)?.start ?? .now
    private var stats: LearningStatistics { store.learningStatistics(for: displayedMonth) }
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)
    private let weekdays = ["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Твой прогресс").font(.headline)
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            metric("Слов в словаре", value: stats.totalWords, icon: "character.book.closed")
                            metric("Освоено", value: stats.masteredWords, icon: "checkmark.seal")
                            metric("Повторений", value: stats.totalReviews, icon: "arrow.2.circlepath")
                            metric("Точность", value: "\(stats.accuracy)%", icon: "target")
                        }
                        HStack {
                            Label("\(stats.currentStreak) дн. подряд", systemImage: "flame")
                            Spacer()
                            Label("\(stats.studyDays) дней занятий", systemImage: "calendar")
                        }
                        .font(.subheadline.weight(.medium)).foregroundStyle(.secondary)
                    }
                    calendar
                    VStack(alignment: .leading, spacing: 10) {
                        Text("За месяц").font(.headline)
                        HStack {
                            summary("Дней", stats.activity.count)
                            Spacer()
                            summary("Повторений", stats.activity.reduce(0) { $0 + $1.reviewCount })
                            Spacer()
                            summary("Новых слов", stats.activity.reduce(0) { $0 + $1.newWordsCount })
                        }
                    }
                    .padding(14)
                    .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
                }
                .padding()
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Профиль")
        }
    }

    private func metric(_ title: String, value: Int, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon).font(.title3).foregroundStyle(.tint)
            Text(String(value)).font(.title2.bold()).contentTransition(.numericText())
            Text(title).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 88, alignment: .leading)
        .padding(12)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
    }

    private var calendar: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(displayedMonth.formatted(.dateTime.month(.wide).year())).font(.headline)
                Spacer()
                Button { changeMonth(-1) } label: { Image(systemName: "chevron.left") }.accessibilityLabel("Предыдущий месяц")
                Button { changeMonth(1) } label: { Image(systemName: "chevron.right") }
                    .disabled(Calendar.current.isDate(displayedMonth, equalTo: .now, toGranularity: .month))
                    .accessibilityLabel("Следующий месяц")
            }
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(weekdays, id: \.self) { Text($0).font(.caption2).foregroundStyle(.secondary) }
                ForEach(Array(cells.enumerated()), id: \.offset) { _, date in
                    if let date {
                        let activity = stats.activity.first { $0.day == StudyActivity.dayKey(for: date) }
                        VStack(spacing: 3) {
                            Text(date.formatted(.dateTime.day())).font(.caption)
                            Circle().fill(activity.map { Color.accentColor.opacity($0.reviewCount >= 10 ? 1 : 0.45) } ?? .clear).frame(width: 6, height: 6)
                        }
                        .frame(maxWidth: .infinity, minHeight: 34)
                        .background(Calendar.current.isDateInToday(date) ? Color.accentColor.opacity(0.12) : .clear, in: RoundedRectangle(cornerRadius: 8))
                        .accessibilityLabel(date.formatted(date: .long, time: .omitted) + (activity.map { ", повторений: \($0.reviewCount)" } ?? ", занятий не было"))
                    } else { Color.clear.frame(height: 34) }
                }
            }
            HStack(spacing: 6) {
                Circle().fill(Color.accentColor.opacity(0.45)).frame(width: 7, height: 7)
                Text("Были занятия").font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    private var cells: [Date?] {
        let cal = Calendar.current
        guard let interval = cal.dateInterval(of: .month, for: displayedMonth),
              let days = cal.range(of: .day, in: .month, for: displayedMonth) else { return [] }
        let offset = (cal.component(.weekday, from: interval.start) + 5) % 7
        var result = Array<Date?>(repeating: nil, count: offset)
        for day in days { result.append(cal.date(byAdding: .day, value: day - 1, to: interval.start)) }
        while result.count % 7 != 0 { result.append(nil) }
        return result
    }

    private func summary(_ title: String, _ value: Int) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(String(value)).font(.title3.bold())
            Text(title).font(.caption).foregroundStyle(.secondary)
        }
    }

    private func changeMonth(_ offset: Int) {
        if let next = Calendar.current.date(byAdding: .month, value: offset, to: displayedMonth) { displayedMonth = next }
    }
}
