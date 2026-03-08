# Materializer

`devenv` module for merging agents instruction fragments across repos.

## Options

- `materializer.ownFragments`
- `materializer.mergedFragments`
- `materializer.materializePath` (default `AGENTS.override.md`)
- `materializer.materializeTemplate` (`plainText` or `codexConfigToml`)
- `materializer.localInputOverrides.matchPattern` (default `Alb-O`)
- `materializer.localInputOverrides.reposRoot` (default `/home/albert/devenv/repos`)
- `materializer.localInputOverrides.sourcePath` (default `devenv.yaml`)
- `materializer.localInputOverrides.outputPath` (default `devenv.local.yaml`)
- `materializer.localInputOverrides.urlScheme` (`path` or `git+file`, default `path`)
- `materializer.localInputOverrides.includeFlakeFalse` (default `true`)

## Output

- `outputs.materialized_text`
- `outputs.materialize_local_input_overrides`

## Commands

- `materialize-local-input-overrides`: scans `devenv.yaml`, matches input URLs containing `matchPattern`, and materializes local overrides into `devenv.local.yaml`.

Example generated override:

```yaml
inputs:
  committer:
    url: path:/home/albert/devenv/repos/committer
    flake: false
```

## Notes

- The `codexConfigToml` value for the `materializeTemplate` option uses codex's `developer_instructions` config key, materializing `.codex/config.toml` instead of `AGENTS.override.md`.
- `devenv` already respects `devenv.local.yaml`; this command only materializes the file.
- Use `materializer.localInputOverrides.urlScheme = "git+file"` if you explicitly want git-backed local input URLs.
