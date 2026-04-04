# Accessibility (macOS SwiftUI)

macOS accessibility is not only VoiceOver. It includes:

- full keyboard access and focus rings
- predictable shortcuts
- readable typography and text-size scaling
- Reduce Motion / Reduce Transparency

## Labels, values, and actions

Prefer explicit accessibility labels when the visual content isn’t plain text:

```swift
Button {
    toggleSidebar()
} label: {
    Image(systemName: "sidebar.left")
}
.accessibilityLabel("Toggle Sidebar")
.accessibilityHint("Shows or hides the sidebar")
```

For dynamic values:

```swift
Text(progressText)
    .accessibilityValue(Text("Progress \(percent) percent"))
```

## Keyboard shortcuts

macOS users expect shortcuts for core actions:

```swift
Button("New Tab") { tabManager.createTab(url: nil) }
    .keyboardShortcut("t", modifiers: [.command])
```

Also consider scene-level shortcuts (for window creation) when using multiple window scenes.

## Focus management

Use `@FocusState` and ensure a logical focus order.

```swift
@FocusState private var focus: Field?
enum Field { case query }

TextField("Search", text: $query)
    .focused($focus, equals: .query)

.onAppear { focus = .query }
```

Test with Full Keyboard Access enabled.

## Text size scaling

macOS text-size preferences are not identical to iOS Dynamic Type, but SwiftUI still provides tools to scale UI consistently.

### Scale fonts

```swift
Text(title)
    .font(.headline.scaled(by: 1.1))
```

For custom fonts, use `Font.custom(_:size:relativeTo:)`.

### Scale layout metrics

Use `@ScaledMetric` for padding, spacing, and icon sizes:

```swift
@ScaledMetric(relativeTo: .body) private var iconSize: CGFloat = 16

Image(systemName: "star")
    .font(.system(size: iconSize))
```

## Reduce motion / transparency

Respect user preferences:

```swift
@Environment(\.accessibilityReduceMotion) private var reduceMotion

func animate(_ body: () -> Void) {
    if reduceMotion { body() }
    else { withAnimation(.spring, body) }
}
```

Similarly, consider `accessibilityReduceTransparency` when using heavy materials.

## Accessibility identifiers for UI tests

Stable identifiers help UI tests and assistive tooling:

```swift
Button("Save") { save() }
    .accessibilityIdentifier("save-button")
```

## Common pitfalls

- Don’t rely on color alone to convey state.
- Don’t disable keyboard focus by wrapping everything in `onTapGesture` instead of using controls.
- Don’t animate essential state changes when Reduce Motion is enabled.

## Primary sources (for verification)

- `Font.scaled(by:)`: https://developer.apple.com/documentation/swiftui/font/scaled%28by%3A%29
- `@ScaledMetric`: https://developer.apple.com/documentation/swiftui/scaledmetric
