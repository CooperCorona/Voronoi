import XCTest
@testable import Voronoi

final class VoronoiTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(Voronoi().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
