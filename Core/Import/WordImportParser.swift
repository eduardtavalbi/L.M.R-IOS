import Foundation

struct WordImportDraft: Identifiable, Equatable {
    let id: UUID
    var text: String
    var translation: String
    var transcription: String
    var example: String
    var duplicateResolution: ImportDuplicateResolution

    init(
        id: UUID = UUID(),
        text: String,
        translation: String,
        transcription: String = "",
        example: String = "",
        duplicateResolution: ImportDuplicateResolution = .skip
    ) {
        self.id = id
        self.text = text
        self.translation = translation
        self.transcription = transcription
        self.example = example
        self.duplicateResolution = duplicateResolution
    }

    var validationError: String? {
        if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return "Нет исходного слова" }
        if translation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return "Нет перевода" }
        return nil
    }
}

enum ImportDuplicateResolution: String, CaseIterable, Identifiable {
    case skip
    case keepBoth
    case merge

    var id: String { rawValue }

    var title: String {
        switch self {
        case .skip: return "Пропустить"
        case .keepBoth: return "Оставить оба"
        case .merge: return "Объединить"
        }
    }
}

struct WordImportSummary: Equatable {
    var imported = 0
    var merged = 0
    var skipped = 0
}

enum WordImportParser {
    enum ParseError: Error, Equatable {
        case noRows
        case unsupportedFormat
    }

    /// Parses tab-, comma-, or semicolon-delimited text. Columns:
    /// word, translation, optional transcription, optional example.
    static func parse(_ source: String) throws -> [WordImportDraft] {
        let lines = source
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .components(separatedBy: "\n")
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        guard !lines.isEmpty else { throw ParseError.noRows }

        let delimiter = detectDelimiter(in: lines[0])
        var rows = lines.compactMap { parseLine($0, delimiter: delimiter) }
        guard !rows.isEmpty else { throw ParseError.noRows }

        if let first = rows.first, isHeader(first) {
            rows.removeFirst()
        }

        let drafts = rows.compactMap { fields -> WordImportDraft? in
            guard fields.count >= 2 else { return nil }
            return WordImportDraft(
                text: fields[0],
                translation: fields[1],
                transcription: fields.count > 2 ? fields[2] : "",
                example: fields.count > 3 ? fields[3] : ""
            )
        }
        guard !drafts.isEmpty else { throw ParseError.unsupportedFormat }
        return drafts
    }

    private static func detectDelimiter(in line: String) -> Character {
        let candidates: [Character] = ["\t", ";", ","]
        return candidates.max { countUnquoted($0, in: line) < countUnquoted($1, in: line) } ?? "\t"
    }

    private static func countUnquoted(_ delimiter: Character, in line: String) -> Int {
        var quoted = false
        var count = 0
        let characters = Array(line)
        var index = 0
        while index < characters.count {
            let character = characters[index]
            if character == "\"" {
                if quoted && index + 1 < characters.count && characters[index + 1] == "\"" {
                    index += 1
                } else {
                    quoted.toggle()
                }
            } else if character == delimiter && !quoted {
                count += 1
            }
            index += 1
        }
        return count
    }

    private static func parseLine(_ line: String, delimiter: Character) -> [String]? {
        var fields: [String] = []
        var field = ""
        var quoted = false
        let characters = Array(line)
        var index = 0

        while index < characters.count {
            let character = characters[index]
            if character == "\"" {
                if quoted && index + 1 < characters.count && characters[index + 1] == "\"" {
                    field.append("\"")
                    index += 1
                } else {
                    quoted.toggle()
                }
            } else if character == delimiter && !quoted {
                fields.append(field.trimmingCharacters(in: .whitespacesAndNewlines))
                field = ""
            } else {
                field.append(character)
            }
            index += 1
        }
        guard !quoted else { return nil }
        fields.append(field.trimmingCharacters(in: .whitespacesAndNewlines))
        return fields
    }

    private static func isHeader(_ fields: [String]) -> Bool {
        guard fields.count >= 2 else { return false }
        let first = fields[0].lowercased()
        let second = fields[1].lowercased()
        let firstHeaders = ["word", "original", "term", "слово", "иностранное слово"]
        let secondHeaders = ["translation", "meaning", "перевод", "значение"]
        return firstHeaders.contains(first) && secondHeaders.contains(second)
    }
}
