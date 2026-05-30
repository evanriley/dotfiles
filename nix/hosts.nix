{ config, inputs, ... }:

{
  flake.nixosConfigurations.cinderace = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";

    modules =
      [
        inputs.disko.nixosModules.disko
        inputs.home-manager.nixosModules.home-manager
        inputs.agenix.nixosModules.default

        (
          { pkgs, ... }:
          {
            environment.systemPackages = [
              inputs.agenix.packages.${pkgs.stdenv.hostPlatform.system}.default
            ];

            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "hm-backup";
            home-manager.users.evan.imports = config.eos.homeModules.evan;
          }
        )
      ]
      ++ config.eos.nixosModules.cinderace;
  };
}
