{ inputs, ... }:

{
  perSystem =
    { pkgs, system, ... }:
    let
      repo = inputs.self;
      lintCheck =
        name: command:
        pkgs.runCommand name
          {
            nativeBuildInputs = with pkgs; [
              deadnix
              findutils
              nixfmt
              statix
            ];
          }
          ''
            cd ${repo}
            ${command}
            touch $out
          '';
    in
    {
      checks =
        if system == "x86_64-linux" then
          {
            cinderace-toplevel = inputs.self.nixosConfigurations.cinderace.config.system.build.toplevel;
            deadnix = lintCheck "deadnix" ''
              deadnix --fail .
            '';
            nixfmt = lintCheck "nixfmt" ''
              find . -name '*.nix' -print0 | xargs -0 nixfmt --check
            '';
            statix = lintCheck "statix" ''
              statix check .
            '';
          }
        else
          { };

      devShells.default = pkgs.mkShell {
        packages = with pkgs; [
          deadnix
          findutils
          git
          nixfmt
          nixfmt-tree
          statix
        ];
      };

      formatter = pkgs.nixfmt-tree;
    };
}
