import XCTest
@testable import Patterns

final class PatternsTests: XCTestCase {
    func testCounterIncrements() {
        let counter = ObservationExamples.Counter()
        XCTAssertEqual(counter.count, 0)
        counter.count += 1
        XCTAssertEqual(counter.count, 1)
    }
}
