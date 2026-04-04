import SwiftUI

struct DebugReproView: View {
  @State private var counter: Int = 0

  var body: some View {
    VStack(spacing: 12) {
      Text("Debug Repro Harness")
        .font(.headline)

      Button("Increment: \(counter)") { counter += 1 }

      #if DEBUG
        let _ = Self._printChanges()
      #endif
    }
    .padding()
    .frame(minWidth: 360, minHeight: 200)
  }
}
