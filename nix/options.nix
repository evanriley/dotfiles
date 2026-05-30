{ lib, ... }:

let
  inherit (lib) mkOption types;
in
{
  options.eos = {
    nixosModules = mkOption {
      type = types.attrsOf (types.listOf types.deferredModule);
      default = { };
      description = "Dendritic NixOS modules grouped by target host or role.";
    };

    homeModules = mkOption {
      type = types.attrsOf (types.listOf types.deferredModule);
      default = { };
      description = "Dendritic Home Manager modules grouped by target user or role.";
    };
  };
}
