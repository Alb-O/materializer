# Composer

`devenv` module for composing files and combining instruction text across repos.

## Options (`composer.*` namespace)

- `projectName` (default `null`: basename of `config.devenv.root`)
- `ownInstructions`
- `composedInstructions`
- `materializePath` (default `AGENTS.override.md`)
- `materializeTemplate` (`plainText` or `codexConfigToml`)

## Shared Instructions (`instructions.*` namespace)

- `instructions.instructions` (list of strings, default `[]`)

`composer` prepends `instructions.instructions` into
`composer.composedInstructions` with `mkBefore`, so producer modules can add
shared instruction text without writing to `composer.*` directly.

## Output

- `outputs.composed_instructions` (only when the effective composed instruction list is non-empty)

## Notes

- The `codexConfigToml` value for the `materializeTemplate` option uses codex's `developer_instructions` config key, materializing `.codex/config.toml` instead of `AGENTS.override.md`.
- Ordering strategy:
  - start with `composer.composedInstructions` in declared order
  - append `composer.ownInstructions.<current-project>` where current project is `composer.projectName` or the basename of `config.devenv.root`
  - de-duplicate by instruction text with keep-last semantics (so the current project instruction ends up last/highest priority)
- The main materialized instruction file is only created when this effective composed instruction list is non-empty.
