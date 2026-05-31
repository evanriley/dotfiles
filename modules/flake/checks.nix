{ inputs, ... }:

{
  perSystem =
    { pkgs, system, ... }:
    {
      checks =
        if system == "x86_64-linux" then
          {
            cinderace-toplevel = inputs.self.nixosConfigurations.cinderace.config.system.build.toplevel;
          }
        else
          { };

      devShells.default = pkgs.mkShell {
        packages = with pkgs; [
          deadnix
          git
          nixfmt
          nixfmt-tree
          statix
        ];
      };

      formatter = pkgs.nixfmt-tree;
    };
}
