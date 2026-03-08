{ pkgs, config, lib, ... }:

let
  cfg = config.materializer;
  materializeLocalInputOverrides = pkgs.writeShellApplication {
    name = "materialize-local-input-overrides";
    runtimeInputs = [ pkgs.python3 ];
    text = ''
      set -euo pipefail

      pattern=${lib.escapeShellArg cfg.localInputOverrides.matchPattern}
      repos_root=${lib.escapeShellArg cfg.localInputOverrides.reposRoot}
      source_path=${lib.escapeShellArg cfg.localInputOverrides.sourcePath}
      output_path=${lib.escapeShellArg cfg.localInputOverrides.outputPath}
      url_scheme=${lib.escapeShellArg cfg.localInputOverrides.urlScheme}
      include_flake_false=${if cfg.localInputOverrides.includeFlakeFalse then "true" else "false"}

      python3 - "$pattern" "$repos_root" "$source_path" "$output_path" "$url_scheme" "$include_flake_false" <<'PY'
import os
import re
import sys

pattern, repos_root, source_path, output_path, url_scheme, include_flake_false_arg = sys.argv[1:7]
include_flake_false = include_flake_false_arg.lower() == "true"

if not os.path.exists(source_path):
    print(f"source file not found: {source_path}", file=sys.stderr)
    sys.exit(1)

with open(source_path, "r", encoding="utf-8") as handle:
    lines = handle.readlines()

entries = []
in_inputs_block = False
current = None

def finish_current():
    global current
    if current is not None and current.get("url"):
        entries.append({"name": current["name"], "url": current["url"]})
    current = None

for raw_line in lines:
    line = raw_line.rstrip("\n")

    if not in_inputs_block:
        if re.match(r"^inputs:\s*$", line):
            in_inputs_block = True
        continue

    if re.match(r"^[A-Za-z0-9_.-]+:\s*$", line):
        finish_current()
        break

    input_match = re.match(r"^  ([A-Za-z0-9_.-]+):\s*$", line)
    if input_match:
        finish_current()
        current = {"name": input_match.group(1), "url": None}
        continue

    if current is None:
        continue

    url_match = re.match(r"^    url:\s*(.+?)\s*$", line)
    if url_match:
        current["url"] = url_match.group(1).strip().strip("'").strip('"')

finish_current()

def repo_name_from_url(url):
    cleaned = url.split("?", 1)[0].split("#", 1)[0]

    if cleaned.startswith("git+"):
        cleaned = cleaned[len("git+"):]

    if cleaned.startswith("github:"):
        cleaned = cleaned[len("github:"):]
    elif "github.com/" in cleaned:
        cleaned = cleaned.split("github.com/", 1)[1]

    cleaned = cleaned.rstrip("/")
    if cleaned.endswith(".git"):
        cleaned = cleaned[:-4]

    if "/" in cleaned:
        cleaned = cleaned.rsplit("/", 1)[1]

    return cleaned or None

overrides = []
missing = []

for entry in entries:
    if pattern not in entry["url"]:
        continue

    repo_name = repo_name_from_url(entry["url"])
    if not repo_name:
        continue

    local_repo_path = os.path.join(repos_root, repo_name)
    if not os.path.isdir(local_repo_path):
        missing.append((entry["name"], local_repo_path))
        continue

    overrides.append((entry["name"], local_repo_path))

overrides.sort(key=lambda item: item[0])

if overrides:
    output_lines = ["inputs:"]
    for input_name, local_repo_path in overrides:
        if url_scheme == "git+file":
            local_url = f"git+file:{local_repo_path}"
        else:
            local_url = f"path:{local_repo_path}"

        output_lines.append(f"  {input_name}:")
        output_lines.append(f"    url: {local_url}")
        if include_flake_false:
            output_lines.append("    flake: false")
else:
    output_lines = ["inputs: {}"]

parent_dir = os.path.dirname(output_path)
if parent_dir:
    os.makedirs(parent_dir, exist_ok=True)

with open(output_path, "w", encoding="utf-8") as handle:
    handle.write("\n".join(output_lines) + "\n")

for input_name, local_repo_path in missing:
    print(f"skipped {input_name}: local repo not found at {local_repo_path}", file=sys.stderr)

print(f"materialized {output_path} with {len(overrides)} override(s)")
PY
    '';
  };

  materializedText =
    if cfg.materializeTemplate == "codexConfigToml"
    then lib.concatStringsSep "\n" [
      "developer_instructions = '''"
      mergedMaterializerText
      "'''"
      ""
    ]
    else mergedMaterializerText;
  mergedMaterializerText = lib.concatStringsSep "\n" cfg.mergedFragments;
  materializedFiles = {
    "${cfg.materializePath}".text = materializedText;
  };
in
{
  options.materializer = {
    ownFragments = lib.mkOption {
      type = with lib.types; attrsOf (listOf str);
      default = {};
      description = "Project-owned instruction fragments keyed by project name.";
    };

    mergedFragments = lib.mkOption {
      type = with lib.types; listOf str;
      default = [];
      description = "Instruction text fragments merged from upstream to downstream repos.";
    };

    materializePath = lib.mkOption {
      type = lib.types.str;
      default = "AGENTS.override.md";
      description = "Relative or absolute output file path to materialize.";
    };

    materializeTemplate = lib.mkOption {
      type = lib.types.enum [ "plainText" "codexConfigToml" ];
      default = "plainText";
      description = "Materialization template: plain text or Codex config TOML.";
    };

    localInputOverrides = {
      matchPattern = lib.mkOption {
        type = lib.types.str;
        default = "Alb-O";
        description = "Substring used to match input URLs eligible for local git+file overrides.";
      };

      reposRoot = lib.mkOption {
        type = lib.types.str;
        default = "/home/albert/devenv/repos";
        description = "Base directory containing local repos used for generated overrides.";
      };

      sourcePath = lib.mkOption {
        type = lib.types.str;
        default = "devenv.yaml";
        description = "Source devenv YAML file to scan for inputs and URLs.";
      };

      outputPath = lib.mkOption {
        type = lib.types.str;
        default = "devenv.local.yaml";
        description = "Output path for generated local input override YAML.";
      };

      urlScheme = lib.mkOption {
        type = lib.types.enum [ "path" "git+file" ];
        default = "path";
        description = "URL scheme used for generated local repo overrides.";
      };

      includeFlakeFalse = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Whether generated overrides include `flake: false` for each matched input.";
      };
    };
  };

  config = {
    files = materializedFiles;
    scripts.materialize-local-input-overrides.exec = "${materializeLocalInputOverrides}/bin/materialize-local-input-overrides";

    outputs.materialized_text = pkgs.writeText "materialized-text.md" mergedMaterializerText;
    outputs.materialize_local_input_overrides = materializeLocalInputOverrides;
  };
}
