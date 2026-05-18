{ pkgs, ... }: {
  services.xserver.videoDrivers = [ "vmware" ];
  virtualisation.vmware.guest.enable = true;
  environment.systemPackages = with pkgs; [
    open-vm-tools
  ];
}
