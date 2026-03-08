#!/usr/bin/env python3
import os
import sys

import yaml


def repo_name_from_url(url: str) -> str | None:
    cleaned = url.split("?", 1)[0].split("#", 1)[0]

    if cleaned.startswith("git+"):
        cleaned = cleaned[len("git+") :]

    if cleaned.startswith("github:"):
        cleaned = cleaned[len("github:") :]
    elif "github.com/" in cleaned:
        cleaned = cleaned.split("github.com/", 1)[1]

    cleaned = cleaned.rstrip("/")
    if cleaned.endswith(".git"):
        cleaned = cleaned[:-4]

    if "/" in cleaned:
        cleaned = cleaned.rsplit("/", 1)[1]

    return cleaned or None


def main() -> int:
    source_yaml_path, pattern, repos_root, url_scheme = sys.argv[1:5]

    with open(source_yaml_path, "r", encoding="utf-8") as handle:
        parsed = yaml.safe_load(handle) or {}

    if not isinstance(parsed, dict):
        raise SystemExit("expected a top-level mapping")

    inputs_block = parsed.get("inputs", {})
    if inputs_block is None:
        inputs_block = {}
    if not isinstance(inputs_block, dict):
        raise SystemExit("expected `inputs` to be a mapping")

    overrides: dict[str, object] = {}

    for input_name, input_spec in inputs_block.items():
        input_url = None
        copied_spec = None

        if isinstance(input_spec, dict):
            candidate_url = input_spec.get("url")
            if isinstance(candidate_url, str) and candidate_url:
                input_url = candidate_url
                copied_spec = dict(input_spec)
        elif isinstance(input_spec, str) and input_spec:
            input_url = input_spec
            copied_spec = {}

        if input_url is None or pattern not in input_url:
            continue

        repo_name = repo_name_from_url(input_url)
        if not repo_name:
            continue

        local_repo_path = os.path.join(repos_root, repo_name)
        if url_scheme == "git+file":
            local_url = f"git+file:{local_repo_path}"
        else:
            local_url = f"path:{local_repo_path}"

        copied_spec["url"] = local_url
        overrides[str(input_name)] = copied_spec

    if not overrides:
        return 0

    output_data = {"inputs": {}}
    for input_name in sorted(overrides):
        output_data["inputs"][input_name] = overrides[input_name]

    yaml.safe_dump(output_data, sys.stdout, sort_keys=True, default_flow_style=False)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
