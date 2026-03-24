import Foundation
import Patterns

@main
struct PatternsCLI {
    static func main() async {
        // Minimal smoke usage that should compile.
        let counter = ObservationExamples.Counter()
        ObservationExamples.printOnChange(counter: counter) { print($0) }
        counter.count += 1

        #if swift(>=6.2)
        await MainActor.run {
            ConcurrencyExamples.orderingDemo { print($0) }
        }
        #endif

        // Keep the process alive briefly so async callbacks can fire in ad-hoc runs.
        try? await Task.sleep(for: .milliseconds(50))
    }
}
