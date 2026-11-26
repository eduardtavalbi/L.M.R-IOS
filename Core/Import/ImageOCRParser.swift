import Foundation
import ImageIO
import PDFKit
import UIKit
import Vision

enum ImageOCRParser {
    enum ParseError: LocalizedError, Equatable {
        case unreadableImage
        case unreadableDocument
        case emptyDocument
        case noRecognizedText

        var errorDescription: String? {
            switch self {
            case .unreadableImage:
                return "Не удалось открыть изображение."
            case .unreadableDocument:
                return "Не удалось открыть PDF-документ."
            case .emptyDocument:
                return "PDF-документ не содержит страниц."
            case .noRecognizedText:
                return "На изображении не удалось распознать текст. Попробуй снимок лучшего качества."
            }
        }
    }

    static func extractText(fromImageData data: Data) throws -> String {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            throw ParseError.unreadableImage
        }
        return try recognizeText(in: image)
    }

    static func extractText(fromPDFData data: Data) throws -> String {
        guard let document = PDFDocument(data: data) else {
            throw ParseError.unreadableDocument
        }
        guard document.pageCount > 0 else {
            throw ParseError.emptyDocument
        }

        var pageTexts: [String] = []
        for index in 0..<document.pageCount {
            guard let page = document.page(at: index),
                  let image = page.thumbnail(
                    of: CGSize(width: 1800, height: 2400),
                    for: .mediaBox
                  ).cgImage else {
                continue
            }
            if let text = try? recognizeText(in: image), !text.isEmpty {
                pageTexts.append(text)
            }
        }

        let text = pageTexts.joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { throw ParseError.noRecognizedText }
        return text
    }

    private static func recognizeText(in image: CGImage) throws -> String {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["zh-Hans", "en-US"]
        request.usesLanguageCorrection = true

        let handler = VNImageRequestHandler(cgImage: image)
        try handler.perform([request])

        let lines = (request.results ?? []).compactMap {
            $0.topCandidates(1).first?.string
        }
        let text = lines.joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { throw ParseError.noRecognizedText }
        return text
    }
}
