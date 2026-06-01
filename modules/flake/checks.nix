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
              gnugrep
              nixfmt
              python3
              shellcheck
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
            shellcheck = lintCheck "shellcheck" ''
              find files/evan -type f -perm -0100 -print0 \
                | while IFS= read -r -d "" file; do
                    if head -n 1 "$file" | grep -Eq '^#!.*(bash|/sh)'; then
                      shellcheck "$file"
                    fi
                  done
            '';
            python-syntax = lintCheck "python-syntax" ''
              export PYTHONPYCACHEPREFIX="$TMPDIR/pycache"
              find files/evan -type f -name '*.py' -print0 \
                | xargs -0 --no-run-if-empty python3 -m py_compile
            '';
          }
        else
          { };

      devShells.default = pkgs.mkShell {
        packages = with pkgs; [
          deadnix
          findutils
          git
          shellcheck
          nixfmt
          nixfmt-tree
          python3
          statix
        ];
      };

      formatter = pkgs.nixfmt-tree;
    };
}
