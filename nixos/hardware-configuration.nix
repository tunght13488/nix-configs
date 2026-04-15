{ lib
, ...
}:
{
  imports = [ ];

  # boot.loader.systemd-boot.enable = true;
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda"; # or "nodev" for efi only
  boot.initrd.availableKernelModules = [
    "ata_piix"
    "mptspi"
    "uhci_hcd"
    "ehci_pci"
    "ahci"
    "sd_mod"
    "sr_mod"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  fileSystems."/" = {
    device = "/dev/sda1";
    fsType = "ext4";
  };

  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 4 * 1024;
    }
  ];

  # Set your system kind (needed for flakes)
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
