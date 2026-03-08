# Materializer

`devenv` module for merging agents instruction fragments across repos.

## Options

- `materializer.projectName` (default `null`: basename of `config.devenv.root`)
- `materializer.ownFragments`
- `materializer.mergedFragments`
- `materializer.materializePath` (default `AGENTS.override.md`)
- `materializer.materializeTemplate` (`plainText` or `codexConfigToml`)
- `materializer.localInputOverrides.matchPattern` (default `Alb-O`)
- `materializer.localInputOverrides.reposRoot` (default `null`: parent of `config.devenv.root`)
- `materializer.localInputOverrides.sourcePath` (default `devenv.yaml`)
- `materializer.localInputOverrides.outputPath` (default `devenv.local.yaml`)
- `materializer.localInputOverrides.urlScheme` (`path` or `git+file`, default `path`)

## Output

- `outputs.materialized_text` (only when the effective merged fragment list is non-empty)
- `outputs.materialized_local_input_overrides` (only when at least one input URL matches `materializer.localInputOverrides.matchPattern`)

Example generated override:

```yaml
inputs:
  committer:
    url: path:/home/albert/devenv/repos/committer
    flake: false
    any_other_key:
      nested: value
```

## Notes

- The `codexConfigToml` value for the `materializeTemplate` option uses codex's `developer_instructions` config key, materializing `.codex/config.toml` instead of `AGENTS.override.md`.
- Ordering strategy:
  - start with `materializer.mergedFragments` in declared order
  - append `materializer.ownFragments.<current-project>` where current project is `materializer.projectName` or the basename of `config.devenv.root`
  - de-duplicate by fragment text with keep-last semantics (so the current project fragment ends up last/highest priority)
- The main materialized instruction file is only created when this effective merged fragment list is non-empty.
- `devenv.local.yaml` is materialized through `files` on shell entry as a symlink to the Nix store (same mechanism as `AGENTS.override.md`) only when at least one input matches.
- For machine-local path overrides, set `materializer.localInputOverrides.reposRoot` in `devenv.local.nix` (untracked).
- Use `materializer.localInputOverrides.urlScheme = "git+file"` if you explicitly want git-backed local input URLs.
- For matched inputs, all existing sibling/child keys are preserved; only `url` is rewritten.
