import Foundation

enum PronunciationAssessment {
    static func normalize(_ text: String) -> String {
        let folded = text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "en_US_POSIX"))
        return String(folded.unicodeScalars.filter { CharacterSet.alphanumerics.contains($0) })
    }

    static func matches(recognized: String, expected: String) -> Bool {
        let actual = normalize(recognized)
        let target = normalize(expected)
        return !actual.isEmpty && !target.isEmpty && actual == target
    }

    static func feedback(recognized: String, expected: String) -> String {
        matches(recognized: recognized, expected: expected)
            ? "Похоже на правильное слово"
            : "Распознанный текст отличается от оригинала"
    }
}
