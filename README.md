# swiftui-macos (Agent Skill)

This repository contains **`swiftui-macos`**, an Agent Skill for writing and reviewing **SwiftUI code on modern macOS** with a runtime-level mental model of:

- **Observation** (`@Observable`, `@ObservationIgnored`, `withObservationTracking`, `Observations`)
- **Concurrency** (Swift 6.x isolation/executors, ordering, Sendable)
- **View identity & performance** (attribute graph, structural identity, identity resets)
- **Platform integration** (AppKit bridging, multi-window scenes, menus/toolbars)

## Scope and platform boundaries

This skill is **macOS-first**:

- **Target OSes:** macOS **15 (Sequoia)** and **26** (and later).
- **Not iOS-first:** avoid UIKit-only guidance (`UIViewRepresentable`, `UIApplicationDelegate`, `UIWindowScene`, iOS-only toolbar placements, iOS-only navigation idioms).
- **When older patterns appear in web search:** treat them as legacy unless they are explicitly supported on macOS 15+.

When writing or reviewing code, prefer explicitly macOS constructs:

- `NSViewRepresentable` / `NSHostingView` (not `UIViewRepresentable` / `UIHostingController`)
- `@NSApplicationDelegateAdaptor` (not `@UIApplicationDelegateAdaptor`)
- macOS scenes: `Settings`, `MenuBarExtra`, `Window`, `WindowGroup(for:)`, `openWindow` / `dismissWindow`
- macOS expectations: menus/commands, keyboard shortcuts, pointer + focus navigation

## Install

### Codex CLI / IDE

Copy the skill directory into a Codex skill search path:

- Per-repository (recommended):

```bash
mkdir -p ./.agents/skills
cp -R ./swiftui-macos ./.agents/skills/
```

- Per-user:

```bash
mkdir -p ~/.agents/skills
cp -R ./swiftui-macos ~/.agents/skills/
```

Codex loads skill metadata automatically. To confirm discovery:

```bash
codex --ask-for-approval never 'List available skills'
```

### Other agents

Agents that implement the `SKILL.md` pattern can typically use the directory as-is.

## Use

In Codex CLI, invoke explicitly:

```text
$swiftui-macos
```

Examples:

- `$swiftui-macos Review why this SwiftUI list is re-rendering excessively`
- `$swiftui-macos Propose a macOS multi-window state architecture for this app`
- `$swiftui-macos Show a correct NSViewRepresentable wrapper for NSTextView with throttled updates`
- `$swiftui-macos Add Find/Replace to a macOS TextEditor and avoid iOS-only recipes`

## Repo structure

```
LICENSE
README.md
AGENTS.md
swiftui-macos/
  SKILL.md
  references/
  scripts/
  assets/
  agents/
.agents/
  skills/
    update-swiftui-macos-skill/   # repo-internal maintenance skill
```

## License

MIT. See [LICENSE](LICENSE).
