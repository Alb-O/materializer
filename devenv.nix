{ pkgs, config, lib, ... }:

let
  cfg = config.agentsInstructions;
  materializedText =
    if cfg.materializeTemplate == "codexConfigToml"
    then lib.concatStringsSep "\n" [
      "developer_instructions = '''"
      agentsInstructionsText
      "'''"
      ""
    ]
    else agentsInstructionsText;
  agentsInstructionsText = lib.concatStringsSep "\n" cfg.mergedFragments;
  materializedFiles = {
    "${cfg.materializePath}".text = materializedText;
  };
in
{
  options.agentsInstructions = {
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
      default = "AGENTS.md";
      description = "Relative or absolute output file path to materialize.";
    };

    materializeTemplate = lib.mkOption {
      type = lib.types.enum [ "plainText" "codexConfigToml" ];
      default = "plainText";
      description = "Materialization template: plain text or Codex config TOML.";
    };
  };

  config = {
    files = materializedFiles;

    outputs.agents_instructions = pkgs.writeText "agents-instructions.md" agentsInstructionsText;
  };
}
