import XCTest
@testable import LMR

final class LMRTests: XCTestCase {
    func testAppInformation() {
        XCTAssertEqual(AppInfo.name, "L.M.R.")
        XCTAssertEqual(AppInfo.fullName, "Learn. Memorize. Repeat.")
    }
}
