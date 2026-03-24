# SwiftUI macOS Skill

A portable **Agent Skill** for writing and reviewing **SwiftUI** code on **macOS** with runtime-level guidance on:

- **Observation** (`@Observable`, `@ObservationIgnored`, `withObservationTracking`, **`Observations` AsyncSequence**)
- **Swift Concurrency** (actor isolation, `Task.immediate`, `@concurrent`, cancellation discipline)
- **View identity & performance** (attribute graph consequences, `.id()`, `EquatableView`, collection rendering)
- **Platform integration** (AppKit bridging with `NSViewRepresentable` / `NSHostingView`, window + menu management)
- **Accessibility** (VoiceOver, keyboard navigation, Dynamic Type, testing workflows)

The skill is **macOS-first** (Sequoia 15 through Tahoe 26). It is not intended for UIKit/iOS-only guidance.

## Repository Layout

This repository is intentionally shaped as a distributable skill bundle:

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
```

## Install (Codex CLI)

Codex discovers skills in repository and user locations. The most common setup is:

- **Per-repo**: copy (or symlink) `swiftui-macos/` into your repo at `.agents/skills/swiftui-macos/`
- **User-wide**: copy `swiftui-macos/` into `~/.agents/skills/swiftui-macos/`

Then invoke explicitly:

```
$swiftui-macos
```

Or let Codex select the skill implicitly by prompt matching (see the `description` field in `swiftui-macos/SKILL.md`). Codex skill discovery and progressive disclosure are documented in OpenAI’s Codex skills docs and the Agent Skills spec.

## Install (Other Agent Runtimes)

This skill follows the open Agent Skills format. Any runtime that supports `SKILL.md` + progressive disclosure can load it. If your agent expects a different discovery location, point it at `swiftui-macos/SKILL.md`.

## Using the Skill

Examples:

- “Review observation discipline and view identity issues in these SwiftUI files.”
- “Help me design a macOS multi-window state architecture with SwiftData.”
- “This view re-renders too often — find the dependency and propose a fix.”
- “Bridge an `NSOutlineView` into SwiftUI without thrashing updates.”

## Contents

- `swiftui-macos/SKILL.md`: activation and instructions (kept intentionally short)
- `swiftui-macos/references/`: deep dives by topic (loaded on demand)
- `swiftui-macos/scripts/`: lightweight validators and repo utilities
- `swiftui-macos/assets/`: reusable Swift snippets and templates

## License

MIT License. See [LICENSE](LICENSE).
