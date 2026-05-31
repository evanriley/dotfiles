{
  eos.homeModules.evan = [
    (
      { pkgs, ... }:
      {
        home.packages = [
          pkgs.syncthing
        ];

        systemd.user.services.syncthing = {
          Unit = {
            Description = "Syncthing";
            Documentation = "https://docs.syncthing.net/";
          };
          Service = {
            ExecStart = "${pkgs.syncthing}/bin/syncthing serve --no-browser --no-restart --logflags=0";
            Restart = "on-failure";
            RestartSec = "5s";
            SuccessExitStatus = [
              3
              4
            ];
            RestartForceExitStatus = [
              3
              4
            ];
          };
          Install.WantedBy = [ "default.target" ];
        };
      }
    )
  ];
}
