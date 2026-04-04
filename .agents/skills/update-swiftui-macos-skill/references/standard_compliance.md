# Standard compliance and repo invariants

This repo must remain compliant with Codex skill standards and the open agent skills specification.

## Required layout (repo root)

- `README.md`
- `AGENTS.md`
- `LICENSE`
- `swiftui-macos/` (primary skill)

## Required layout (primary skill)

Inside `swiftui-macos/`:

- `SKILL.md` with frontmatter (`name`, `description`, `license`, `compatibility`, `metadata.version`)
- `references/` (topic deep dives)
- `assets/` (compile-checked examples, templates)
- `scripts/` (verification helpers)
- `agents/` (optional agent config such as `openai.yaml`)

## Required layout (repo-internal maintenance skill)

Inside `.agents/skills/update-swiftui-macos-skill/`:

- `SKILL.md`
- `references/` and `scripts/` (optional but used here)

## Integrity checks

- All relative markdown links must resolve (run `swiftui-macos/scripts/verify.sh`).
- Avoid adding absolute-path links in markdown.
- Keep examples compiling on a macOS machine that targets macOS 15+.
