import Foundation
import SwiftUI
import UniformTypeIdentifiers

enum WordCSVExporter {
    static func data(for words: [Word]) -> Data {
        let header = ["Word", "Translation", "Transcription", "Notes", "Example"]
        let rows = [header] + words.map { word in
            [
                word.text,
                word.translation,
                word.transcription ?? "",
                word.notes ?? "",
                word.example ?? ""
            ]
        }
        let content = rows.map { $0.map(escape).joined(separator: ",") }.joined(separator: "\r\n")
        return Data(("\u{FEFF}" + content).utf8)
    }

    private static func escape(_ value: String) -> String {
        guard value.contains(",") || value.contains("\"") || value.contains("\n") || value.contains("\r") else {
            return value
        }
        return "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }
}

struct WordCSVDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.commaSeparatedText] }
    var data: Data

    init(data: Data) { self.data = data }

    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}
