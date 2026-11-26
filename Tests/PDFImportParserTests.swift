import XCTest
import UIKit
@testable import LMR

final class PDFImportParserTests: XCTestCase {
    func testExtractsTextFromPDFPagesInOrder() throws {
        let data = makePDF(pages: ["apple\tяблоко", "book\tкнига"])
        let text = try PDFImportParser.extractText(from: data)

        XCTAssertTrue(text.contains("apple"))
        XCTAssertTrue(text.contains("яблоко"))
        XCTAssertTrue(text.contains("book"))
        XCTAssertTrue(text.contains("книга"))
        XCTAssertLessThan(try XCTUnwrap(text.range(of: "apple")).lowerBound, try XCTUnwrap(text.range(of: "book")).lowerBound)
    }

    func testRejectsInvalidPDFData() {
        XCTAssertThrowsError(try PDFImportParser.extractText(from: Data("not a PDF".utf8)))
    }

    private func makePDF(pages: [String]) -> Data {
        let bounds = CGRect(x: 0, y: 0, width: 612, height: 792)
        let renderer = UIGraphicsPDFRenderer(bounds: bounds)
        return renderer.pdfData { context in
            for pageText in pages {
                context.beginPage()
                (pageText as NSString).draw(
                    at: CGPoint(x: 40, y: 40),
                    withAttributes: [.font: UIFont.systemFont(ofSize: 18)]
                )
            }
        }
    }
}
