import XCTest
@testable import LMR

final class WordImportParserTests: XCTestCase {
    func testParsesTabSeparatedPairs() throws {
        let rows = try WordImportParser.parse("apple\tяблоко\nbook\tкнига")
        XCTAssertEqual(rows.map(\.text), ["apple", "book"])
        XCTAssertEqual(rows.map(\.translation), ["яблоко", "книга"])
    }

    func testParsesCSVWithQuotedCommaAndOptionalColumns() throws {
        let rows = try WordImportParser.parse("word,translation,transcription,example\nhello,привет,həˈləʊ,\"Hello, world!\"")
        XCTAssertEqual(rows.count, 1)
        XCTAssertEqual(rows[0].text, "hello")
        XCTAssertEqual(rows[0].translation, "привет")
        XCTAssertEqual(rows[0].transcription, "həˈləʊ")
        XCTAssertEqual(rows[0].example, "Hello, world!")
    }

    func testParsesSemicolonSeparatedRows() throws {
        let rows = try WordImportParser.parse("你好;привет\n谢谢;спасибо")
        XCTAssertEqual(rows.map(\.text), ["你好", "谢谢"])
    }

    func testSupportsEscapedQuotes() throws {
        let rows = try WordImportParser.parse("word,translation,transcription,example\nbook,книга,,\"He said \"\"hello\"\".\"")
        XCTAssertEqual(rows.first?.example, "He said \"hello\".")
    }

    func testDetectsHeaderAndSkipsEmptyLines() throws {
        let rows = try WordImportParser.parse("Word\tTranslation\n\napple\tяблоко\n")
        XCTAssertEqual(rows.count, 1)
    }

    func testValidatesRequiredFields() {
        XCTAssertEqual(WordImportDraft(text: " ", translation: "перевод").validationError, "Нет исходного слова")
        XCTAssertEqual(WordImportDraft(text: "word", translation: "").validationError, "Нет перевода")
        XCTAssertNil(WordImportDraft(text: "word", translation: "слово").validationError)
    }

    func testEmptyInputThrows() {
        XCTAssertThrowsError(try WordImportParser.parse(" \n\t\n"))
    }

    func testParsesSpreadsheetRowsUsingSelectedColumns() throws {
        let rows = try WordImportParser.parse(
            rows: [
                ["Word", "Translation", "IPA", "Sentence", "Notes"],
                ["hello", "привет", "həˈləʊ", "Hello there!", "keep"],
                ["book", "книга", "", "", ""]
            ],
            columnIndices: [0, 1, 2, 3]
        )
        XCTAssertEqual(rows.count, 2)
        XCTAssertEqual(rows[0].text, "hello")
        XCTAssertEqual(rows[0].translation, "привет")
        XCTAssertEqual(rows[0].transcription, "həˈləʊ")
        XCTAssertEqual(rows[0].example, "Hello there!")
    }

    func testSpreadsheetColumnMappingCanReorderFields() throws {
        let rows = try WordImportParser.parse(
            rows: [["translation", "word"], ["яблоко", "apple"]],
            columnIndices: [1, 0]
        )
        XCTAssertEqual(rows.first?.text, "apple")
        XCTAssertEqual(rows.first?.translation, "яблоко")
        XCTAssertEqual(rows.first?.transcription, "")
    }
}
