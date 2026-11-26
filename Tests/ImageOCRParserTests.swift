import XCTest
@testable import LMR

final class ImageOCRParserTests: XCTestCase {
    func testRejectsInvalidImageData() {
        XCTAssertThrowsError(try ImageOCRParser.extractText(fromImageData: Data("not an image".utf8))) { error in
            XCTAssertEqual(error as? ImageOCRParser.ParseError, .unreadableImage)
        }
    }

    func testRejectsInvalidPDFData() {
        XCTAssertThrowsError(try ImageOCRParser.extractText(fromPDFData: Data("not a PDF".utf8))) { error in
            XCTAssertEqual(error as? ImageOCRParser.ParseError, .unreadableDocument)
        }
    }
}
