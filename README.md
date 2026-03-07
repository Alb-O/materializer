# Agents Instructions Builder

`devenv` module for merging agents instruction fragments across repos.

## Options

- `agentsInstructions.ownFragments`
- `agentsInstructions.mergedFragments`
- `agentsInstructions.materializePath` (default `AGENTS.md`)
- `agentsInstructions.materializeTemplate` (`plainText` or `codexConfigToml`)

## Output

- `outputs.agents_instructions`

## Notes

- The `codexConfigToml` value for the `materializeTemplate` option uses codex's `developer_instructions` config key, materializing `.codex/config.toml` instead of `AGENTS.md`.
