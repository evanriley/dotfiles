{ inputs, ... }:

{
  flake.nixosConfigurations.cinderace = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";

    modules = [
      inputs.disko.nixosModules.disko
      inputs.home-manager.nixosModules.home-manager
      inputs.agenix.nixosModules.default

      (
        { pkgs, ... }:
        {
          environment.systemPackages = [
            inputs.agenix.packages.${pkgs.stdenv.hostPlatform.system}.default
          ];

          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            backupFileExtension = "hm-backup";
            users.evan.imports = with inputs.self.homeModules; [
              evanBase
              evanDesktop
              evanMediaContainers
              evanMpd
              evanSync
            ];
          };
        }
      )
      inputs.self.modules.nixos.cinderaceDesktop
      inputs.self.modules.nixos.cinderaceDisko
      inputs.self.modules.nixos.cinderaceMediaContainers
      inputs.self.modules.nixos.cinderaceSecrets
      inputs.self.modules.nixos.cinderaceSystem
    ];
  };
}
