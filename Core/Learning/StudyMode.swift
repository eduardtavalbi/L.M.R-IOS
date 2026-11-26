import Foundation

enum StudyMode: String, CaseIterable, Identifiable {
    case flashcards
    case multipleChoice
    case typing

    var id: String { rawValue }

    var title: String {
        switch self {
        case .flashcards: "Карточки"
        case .multipleChoice: "Выбор ответа"
        case .typing: "Ввод ответа"
        }
    }

    var symbol: String {
        switch self {
        case .flashcards: "rectangle.on.rectangle"
        case .multipleChoice: "list.bullet.circle"
        case .typing: "keyboard"
        }
    }
}

enum StudyModeEngine {
    static func answersMatch(_ answer: String, expected: String) -> Bool {
        normalize(answer) == normalize(expected) && !normalize(answer).isEmpty
    }

    static func multipleChoiceOptions(for word: Word, from words: [Word], limit: Int = 4) -> [String] {
        guard limit > 1 else { return [] }
        let correct = word.translation.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !correct.isEmpty else { return [] }

        var seen = Set([normalize(correct)])
        let distractors = words.compactMap { candidate -> String? in
            let value = candidate.translation.trimmingCharacters(in: .whitespacesAndNewlines)
            let key = normalize(value)
            guard !key.isEmpty, seen.insert(key).inserted else { return nil }
            return value
        }
        let selected = Array(distractors.shuffled().prefix(limit - 1))
        return (selected + [correct]).shuffled()
    }

    private static func normalize(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
    }
}
