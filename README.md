# swiftui-macos (Agent Skill)

This repository contains **`swiftui-macos`**, an Agent Skill for writing and reviewing **SwiftUI code on macOS** with a runtime-level mental model of:

- Observation (`@Observable`, `@ObservationIgnored`, `withObservationTracking`, and `Observations`)
- Concurrency (Swift 6.2 “approachable concurrency”, default actor isolation, and execution ordering)
- View identity & performance (attribute graph, structural identity, `Equatable` views)
- Platform integration (AppKit bridging, multi-window, scenes)

The skill follows the **OpenAI Codex / open agent skills** format: a single directory containing `SKILL.md` plus optional `scripts/`, `references/`, and `assets/`.

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
```

## License

MIT. See [LICENSE](LICENSE).
