# AGENTS

This repository is a **portable Agent Skill** bundle. Agentic tools should treat it like a small, versioned library:
- keep the entrypoint (`swiftui-macos/SKILL.md`) concise
- keep detailed guidance in `swiftui-macos/references/`
- keep executable utilities in `swiftui-macos/scripts/`
- keep reusable code in `swiftui-macos/assets/`

## Working Agreement for Agentic Changes

### Always do
1. **Respect scope**: this skill is **macOS SwiftUI**, not UIKit/iOS.
2. **Prefer official sources** when validating claims:
   - Apple Developer Documentation
   - Swift Evolution proposals / Swift.org release notes
   - WWDC session pages
3. **Avoid invented APIs**: if unsure, add a link in `swiftui-macos/references/sources.md` and phrase guidance as conditional.
4. **Keep progressive disclosure intact**:
   - `swiftui-macos/SKILL.md` should stay under ~300 lines.
   - Put deep details in topic files under `references/`.
5. **Avoid brittle microbench numbers** (byte counts, exact allocation sizes). Prefer:
   - relative cost ordering
   - profiling instructions (Instruments, signposts, Time Profiler)
   - “measure in your app” guidance.

### Ask first (human review recommended)
- Adding new third‑party dependencies.
- Introducing guidance that relies on private API, swizzling, or undocumented behavior.
- Changing the skill’s scope (e.g., expanding to iOS/UIKit).

## Editing Workflow

### 1) Update instructions
- Entry point: `swiftui-macos/SKILL.md`
- Topic docs: `swiftui-macos/references/*.md`
- Source index: `swiftui-macos/references/sources.md` (add links when validating or updating behavior)

### 2) Keep examples runnable
Reusable Swift snippets live in `swiftui-macos/assets/snippets/`. Prefer minimal, copy‑paste‑ready examples.

### 3) Validate the skill bundle
Run:

```bash
python3 swiftui-macos/scripts/validate_skill.py
```

This performs structural checks (frontmatter name match, required files, broken internal references).

If you have the community validator installed, you can also run:

```bash
skills-ref validate ./swiftui-macos
```

### 4) Versioning
- Bump `metadata.version` in `swiftui-macos/SKILL.md`
- Append a short entry to `swiftui-macos/CHANGELOG.md`

## Repository Structure (canonical)

```
swiftui-macos/
  SKILL.md
  CHANGELOG.md
  agents/openai.yaml
  references/
    sources.md
    observation.md
    concurrency.md
    performance.md
    views.md
    data.md
    platform.md
    api.md
    accessibility.md
  scripts/
    validate_skill.py
  assets/
    icons/
    snippets/
```
