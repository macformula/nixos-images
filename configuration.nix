
{ config, pkgs, ... }:

{
  # preference
  nix.settings.experimental-features = [ "nix-command" "flakes"];

  networking.hostName = "macfe";

  # ethernet
  networking.useDHCP = false;
  networking.useNetworkd = true;
  # once we have multiple pis, this may want to be per-pi, although unlikely that anyone connects to 2 pis at once
  systemd.network.networks."10-wired" = {
    matchConfig.Type = "ether";
    address = [ "192.168.50.2/24" ];
    linkConfig.RequiredForOnline = "no";
  };

  # use ethernet instead. 
  networking.wireless.enable = false;

  # ssh
  services.openssh.enable = true;
  services.openssh.settings = {
    PasswordAuthentication = true;
    PermitRootLogin = "no";
  };

  # make group gpio
  users.groups.gpio = {};
  # look at everything in gpio that is a gpiochip, make it readable and writable
  # to find gpio and other subsystems, look at /sys/bus/, and the /sys/ directory more broadly
  #bcm2835-gpiomem is pi-specific but good since we are flipping registers
  services.udev.extraRules = ''
    SUBSYSTEM=="gpio", KERNEL=="gpiochip*", GROUP="gpio", MODE="0660"
  '';
  users.users.pi = {
    isNormalUser = true;
    extraGroups = ["wheel" "gpio"];
    # since we are only ever accessing over ethernet directly to laptop, this is OK. 
    initialPassword = "pi";
  };
  # for the same reason, this is ok
  security.sudo.wheelNeedsPassword = false;

  environment.systemPackages = with pkgs; [
    neovim # nvim
    tree # display files
    iproute2 #show ip (ip addr) (run man ip for more)
    libgpiod # talk to gpio (only for cli testing, actually talk to gpio in code)
    tmux # run many things. Keep in mind that you can also tmux on your laptop and open many ssh terminals, but this is convenient
    can-utils # can. Eventually reference this once we know what spi to can board we're using https://copperhilltech.com/blog/beginners-guide-to-using-socketcan-with-raspberry-pi-and-pican-board/
    
  ];

  system.stateVersion = "25.11";
}

