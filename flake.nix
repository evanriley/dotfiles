{
  description = "Evan Riley's systems";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{ flake-parts, ... }:
    let
      lib = inputs.nixpkgs.lib;

      dendriticModules =
        dir:
        let
          entries = builtins.readDir dir;
          names = builtins.attrNames entries;
          isModule = name: entries.${name} == "regular" && lib.hasSuffix ".nix" name;
          isDir = name: entries.${name} == "directory";
          files = map (name: dir + "/${name}") (builtins.filter isModule names);
          dirs = lib.concatMap (name: dendriticModules (dir + "/${name}")) (builtins.filter isDir names);
        in
        files ++ dirs;
    in
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = dendriticModules ./nix;

      systems = [
        "x86_64-linux"
        "aarch64-darwin"
      ];
    };
}
