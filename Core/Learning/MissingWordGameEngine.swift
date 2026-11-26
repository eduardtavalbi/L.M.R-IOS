import Foundation

enum MissingWordGameEngine {
    static func eligibleWords(_ words: [Word]) -> [Word] {
        words.filter { word in
            let example = word.example?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let prompt = word.text.trimmingCharacters(in: .whitespacesAndNewlines)
            return !prompt.isEmpty
                && !word.translation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                && !example.isEmpty
                && example.range(of: prompt, options: [.caseInsensitive]) != nil
        }
    }

    static func sentenceWithMissingWord(for word: Word) -> String? {
        guard let example = word.example,
              !word.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let range = example.range(of: word.text, options: [.caseInsensitive]) else {
            return nil
        }
        return example.replacingOccurrences(of: word.text, with: "_______", options: [.caseInsensitive])
    }

    static func answersMatch(_ answer: String, expected: String) -> Bool {
        StudyModeEngine.answersMatch(answer, expected: expected)
    }
}
