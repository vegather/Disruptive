import XCTest
@testable import Disruptive

final class DisruptiveTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(Disruptive().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
