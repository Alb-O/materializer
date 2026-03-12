{
  pkgs,
  config,
  lib,
  ...
}:

let
  cfg = config.composer;
  currentProjectName =
    if cfg.projectName != null then
      cfg.projectName
    else
      builtins.baseNameOf (toString config.devenv.root);
  currentProjectOwnInstructions = lib.attrByPath [ currentProjectName ] [ ] cfg.ownInstructions;
  effectiveComposedInstructions = lib.reverseList (
    lib.unique (lib.reverseList (cfg.composedInstructions ++ currentProjectOwnInstructions))
  );

  collapseConsecutiveBlankLines =
    text:
    let
      folded =
        lib.foldl'
          (
            acc: line:
            let
              isBlank = builtins.match "^[ \t\r]*$" line != null;
            in
            if isBlank && acc.previousBlank then
              acc
            else
              {
                previousBlank = isBlank;
                revLines = [ line ] ++ acc.revLines;
              }
          )
          {
            previousBlank = false;
            revLines = [ ];
          }
          (lib.splitString "\n" text);
    in
    lib.concatStringsSep "\n" (lib.reverseList folded.revLines);
  rawComposedInstructionsText = lib.concatStringsSep "\n" effectiveComposedInstructions;
  composedInstructionsText = collapseConsecutiveBlankLines rawComposedInstructionsText;
  renderedMaterializedText =
    if cfg.materializeTemplate == "codexConfigToml" then
      lib.concatStringsSep "\n" [
        "developer_instructions = '''"
        composedInstructionsText
        "'''"
        ""
      ]
    else
      composedInstructionsText;
in
{
  options = {
    instructions.instructions = lib.mkOption {
      type = with lib.types; listOf str;
      default = [ ];
      description = "Shared instruction text that modules can add.";
    };

    composer = {
      projectName = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Current project key used to resolve `ownInstructions.<projectName>`. Defaults to the basename of `config.devenv.root`.";
      };

      ownInstructions = lib.mkOption {
        type = with lib.types; attrsOf (listOf str);
        default = { };
        description = "Project-owned instruction text keyed by project name.";
      };

      composedInstructions = lib.mkOption {
        type = with lib.types; listOf str;
        default = [ ];
        description = "Instruction text composed from upstream to downstream repos.";
      };

      materializePath = lib.mkOption {
        type = lib.types.str;
        default = "AGENTS.override.md";
        description = "Relative or absolute output file path to materialize.";
      };

      materializeTemplate = lib.mkOption {
        type = lib.types.enum [
          "plainText"
          "codexConfigToml"
        ];
        default = "plainText";
        description = "Materialization template: plain text or Codex config TOML.";
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf (config.instructions.instructions != [ ]) {
      composer.composedInstructions = lib.mkBefore config.instructions.instructions;
    })
    (lib.mkIf (effectiveComposedInstructions != [ ]) {
      files."${cfg.materializePath}".text = renderedMaterializedText;
      outputs.composed_instructions = pkgs.writeText "composed-instructions.md" composedInstructionsText;
    })
  ];
}
