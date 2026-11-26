import Foundation
import PDFKit

enum PDFImportParser {
    enum ParseError: LocalizedError {
        case unreadableDocument
        case emptyDocument
        case noExtractableText

        var errorDescription: String? {
            switch self {
            case .unreadableDocument:
                return "Не удалось открыть PDF-документ."
            case .emptyDocument:
                return "PDF-документ не содержит страниц."
            case .noExtractableText:
                return "В PDF не найден текст. Возможно, это скан — для него понадобится OCR."
            }
        }
    }

    static func extractText(from data: Data) throws -> String {
        guard let document = PDFDocument(data: data) else {
            throw ParseError.unreadableDocument
        }
        guard document.pageCount > 0 else {
            throw ParseError.emptyDocument
        }

        let pageTexts = (0..<document.pageCount).compactMap { index -> String? in
            guard let page = document.page(at: index) else { return nil }
            return page.string
        }
        let text = pageTexts
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: "\n")

        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ParseError.noExtractableText
        }
        return text
    }
}
