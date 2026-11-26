import CoreXLSX
import Foundation

struct XLSXWorksheet: Identifiable {
    let id: String
    let name: String
    let rows: [[String]]
}

enum XLSXImportParser {
    enum ParseError: Error {
        case invalidWorkbook
        case noWorksheets
    }

    static func parse(data: Data) throws -> [XLSXWorksheet] {
        let file = try XLSXFile(data: data)
        let sharedStrings = try file.parseSharedStrings()
        var result: [XLSXWorksheet] = []

        for workbook in try file.parseWorkbooks() {
            for (index, sheet) in try file.parseWorksheetPathsAndNames(workbook: workbook).enumerated() {
                let worksheet = try file.parseWorksheet(at: sheet.path)
                let rows = (worksheet.data?.rows ?? []).map { row -> [String] in
                    let cells = row.cells.map { cell in
                        (columnIndex(cell.reference.column.value), cellValue(cell, sharedStrings: sharedStrings))
                    }
                    let width = (cells.map(\.0).max() ?? 0) + 1
                    var values = Array(repeating: "", count: width)
                    for (column, value) in cells where values.indices.contains(column) {
                        values[column] = value
                    }
                    return values
                }
                result.append(
                    XLSXWorksheet(
                        id: sheet.path,
                        name: sheet.name ?? "Лист \(index + 1)",
                        rows: rows
                    )
                )
            }
        }

        guard !result.isEmpty else { throw ParseError.noWorksheets }
        return result
    }

    private static func cellValue(_ cell: Cell, sharedStrings: SharedStrings?) -> String {
        if let sharedStrings {
            return cell.stringValue(sharedStrings) ?? cell.inlineString?.text ?? ""
        }
        return cell.inlineString?.text ?? cell.value ?? ""
    }

    private static func columnIndex(_ letters: String) -> Int {
        letters.uppercased().unicodeScalars.reduce(0) { value, scalar in
            value * 26 + Int(scalar.value - 64)
        } - 1
    }
}
