{
  flake.modules.nixos.cinderaceDisko = {
    disko.devices = {
      disk.main = {
        type = "disk";
        # The 2 TB 9100 PRO in PCIe slot 04:00.0 is cinderace's OS disk.
        # Do not use /dev/nvmeXnY names here; their numbering is not stable.
        device = "/dev/disk/by-path/pci-0000:04:00.0-nvme-1";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              label = "ESP";
              size = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ];
              };
            };

            cryptroot = {
              label = "nixos-cryptroot";
              size = "100%";
              content = {
                type = "luks";
                name = "crypted";
                settings = {
                  allowDiscards = true;
                };
                content = {
                  type = "btrfs";
                  extraArgs = [ "-f" ];
                  subvolumes = {
                    "/root" = {
                      mountpoint = "/";
                      mountOptions = [
                        "compress=zstd"
                        "noatime"
                      ];
                    };
                    "/home" = {
                      mountpoint = "/home";
                      mountOptions = [
                        "compress=zstd"
                        "noatime"
                      ];
                    };
                    "/nix" = {
                      mountpoint = "/nix";
                      mountOptions = [
                        "compress=zstd"
                        "noatime"
                      ];
                    };
                    "/var" = {
                      mountpoint = "/var";
                      mountOptions = [
                        "compress=zstd"
                        "noatime"
                      ];
                    };
                  };
                };
              };
            };
          };
        };
      };
    };
  };
}
