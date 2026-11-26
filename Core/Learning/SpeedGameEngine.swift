import Foundation

enum SpeedGameEngine {
    static func eligibleWords(_ words: [Word]) -> [Word] {
        words.filter {
            !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                && !$0.translation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    static func answersMatch(_ answer: String, expected: String) -> Bool {
        StudyModeEngine.answersMatch(answer, expected: expected)
    }

    static func points(forCorrectAnswer streak: Int) -> Int {
        1 + max(0, streak - 1) / 5
    }
}
