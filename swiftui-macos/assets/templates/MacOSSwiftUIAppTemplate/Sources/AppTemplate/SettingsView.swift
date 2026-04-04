import SwiftUI

struct SettingsView: View {
  var body: some View {
    Form {
      Text("Preferences")
        .font(.headline)

      Text("Wire app preferences here (UserDefaults, SwiftData, etc.)")
        .foregroundStyle(.secondary)
    }
    .padding()
    .frame(width: 420)
  }
}
