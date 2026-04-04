import XCTest

@testable import Patterns

final class PatternsTests: XCTestCase {
  func testCounterIncrements() async {
    await MainActor.run {
      let counter = ObservationExamples.Counter()

      let initialCount = counter.count
      XCTAssertEqual(initialCount, 0)

      counter.count += 1
      let updatedCount = counter.count
      XCTAssertEqual(updatedCount, 1)
    }
  }
}
