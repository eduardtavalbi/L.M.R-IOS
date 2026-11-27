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

    /// Parses tab-, comma-, or semicolon-delimited text, including quoted fields
    /// that contain delimiters, escaped quotes, and embedded line breaks.
    static func parse(_ source: String) throws -> [WordImportDraft] {
        let normalized = source
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
        guard !normalized.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ParseError.noRows
        }

        let delimiter = detectDelimiter(in: normalized.components(separatedBy: "\n").first ?? normalized)
        let fields = try parseRecords(normalized, delimiter: delimiter)
        return try parse(rows: fields)
    }

    /// Converts already separated spreadsheet rows using zero-based column indexes.
    static func parse(rows: [[String]], columnIndices: [Int] = [0, 1, 2, 3]) throws -> [WordImportDraft] {
        guard !rows.isEmpty else { throw ParseError.noRows }
        guard columnIndices.count >= 2, columnIndices.allSatisfy({ $0 >= 0 }) else {
            throw ParseError.unsupportedFormat
        }

        var sourceRows = rows.filter { $0.contains { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty } }
        guard !sourceRows.isEmpty else { throw ParseError.noRows }

        if let first = sourceRows.first, isHeader(first, columnIndices: Array(columnIndices.prefix(2))) {
            sourceRows.removeFirst()
        }

        let drafts = sourceRows.map { row in
            func value(at mappingIndex: Int) -> String {
                guard columnIndices.indices.contains(mappingIndex) else { return "" }
                let column = columnIndices[mappingIndex]
                guard row.indices.contains(column) else { return "" }
                return row[column].trimmingCharacters(in: .whitespacesAndNewlines)
            }

            return WordImportDraft(
                text: value(at: 0),
                translation: value(at: 1),
                transcription: value(at: 2),
                example: value(at: 3)
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

    private static func parseRecords(_ source: String, delimiter: Character) throws -> [[String]] {
        var records: [[String]] = []
        var fields: [String] = []
        var field = ""
        var inQuotes = false
        var afterClosingQuote = false
        let characters = Array(source)
        var index = 0

        func finishField() {
            fields.append(field.trimmingCharacters(in: .whitespacesAndNewlines))
            field = ""
            afterClosingQuote = false
        }

        func finishRecord() {
            finishField()
            if fields.contains(where: { !$0.isEmpty }) {
                records.append(fields)
            }
            fields = []
        }

        while index < characters.count {
            let character = characters[index]

            if inQuotes {
                if character == "\"" {
                    if index + 1 < characters.count && characters[index + 1] == "\"" {
                        field.append("\"")
                        index += 1
                    } else {
                        inQuotes = false
                        afterClosingQuote = true
                    }
                } else {
                    field.append(character)
                }
            } else if afterClosingQuote {
                if character == delimiter {
                    finishField()
                } else if character == "\n" {
                    finishRecord()
                } else if character.isWhitespace {
                    // Ignore padding between a closing quote and the next separator.
                } else {
                    throw ParseError.unsupportedFormat
                }
            } else if character == delimiter {
                finishField()
            } else if character == "\n" {
                finishRecord()
            } else if character == "\"" {
                guard field.trimmingCharacters(in: .whitespaces).isEmpty else {
                    throw ParseError.unsupportedFormat
                }
                field = ""
                inQuotes = true
            } else {
                field.append(character)
            }
            index += 1
        }

        guard !inQuotes else { throw ParseError.unsupportedFormat }
        if !field.isEmpty || !fields.isEmpty || afterClosingQuote {
            finishRecord()
        }
        guard !records.isEmpty else { throw ParseError.noRows }
        return records
    }

    private static func isHeader(_ fields: [String], columnIndices: [Int] = [0, 1]) -> Bool {
        guard columnIndices.count >= 2,
              fields.indices.contains(columnIndices[0]),
              fields.indices.contains(columnIndices[1]) else { return false }
        let first = fields[columnIndices[0]].lowercased()
        let second = fields[columnIndices[1]].lowercased()
        let firstHeaders = ["word", "original", "term", "слово", "иностранное слово"]
        let secondHeaders = ["translation", "meaning", "перевод", "значение"]
        return firstHeaders.contains(first) && secondHeaders.contains(second)
    }
}
