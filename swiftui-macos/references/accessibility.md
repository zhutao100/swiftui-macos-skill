# Accessibility (macOS SwiftUI)

macOS accessibility is not only VoiceOver. It includes:

- full keyboard access and focus rings
- predictable shortcuts
- readable typography and scaling
- reduce motion / reduce transparency

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
    .accessibilityValue(Text("Progress \(percent)%"))
```

## Keyboard shortcuts

macOS users expect shortcuts for core actions:

```swift
Button("New Tab") { tabManager.createTab(url: nil) }
    .keyboardShortcut("t", modifiers: [.command])
```

## Focus management

Use `@FocusState` and ensure a logical focus order.

```swift
@FocusState private var focus: Field?

enum Field { case query }

TextField("Search", text: $query)
    .focused($focus, equals: .query)

.onAppear { focus = .query }
```

## Dynamic Type and scaling

### Scale fonts

SwiftUI supports scaling fonts relative to a base style:

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

Stable identifiers help both UI tests and assistive tooling:

```swift
Button("Save") { save() }
    .accessibilityIdentifier("save-button")
```

## Common pitfalls

- Don’t rely on color alone to convey state.
- Don’t disable keyboard focus by wrapping everything in `onTapGesture` instead of using controls.
- Don’t animate essential state changes when Reduce Motion is enabled.
