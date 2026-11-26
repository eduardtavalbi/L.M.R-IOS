import Foundation

enum AudioChoiceGameEngine {
    static func options(for word: Word, from words: [Word], limit: Int = 4) -> [String] {
        StudyModeEngine.multipleChoiceOptions(for: word, from: words, limit: limit)
    }

    static func canPlay(_ word: Word) -> Bool {
        !word.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !word.translation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    static func canPlayGame(with words: [Word]) -> Bool {
        let eligible = words.filter(canPlay)
        let translations = Set(eligible.map {
            $0.translation.trimmingCharacters(in: .whitespacesAndNewlines)
                .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
        })
        return eligible.count >= 2 && translations.count >= 2
    }
}
