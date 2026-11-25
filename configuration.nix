{ config, pkgs, ... }:

{
  # preference
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

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

  systemd.network.networks."40-can0" = {
    matchConfig.Name = "can0";
    canConfig = {
      BitRate = 500000;
      RestartSec = "100ms";
    };
  };

  systemd.network.links."40-can0" = {
    matchConfig.OriginalName = "can0";
    linkConfig.TransmitQueueLength = 1000;
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
  users.groups.gpio = { };

  services.udev.extraRules = ''
    SUBSYSTEM=="bcm2835-gpiomem", KERNEL=="gpiomem", GROUP="gpio", MODE = "0660"
  '';
  users.users.pi = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "gpio"
    ];
    # since we are only ever accessing over ethernet directly to laptop, this is OK.
    initialPassword = "pi";
  };
  # for the same reason, this is ok
  security.sudo.wheelNeedsPassword = false;
  nix.settings.trusted-users = [ "root" "pi" ];

  # these can be quick-added with nixos-rebuild switch --flake .#rpi4-image --target-host pi@192.168.50.2 --sudo. That can be done elsewhere,
  # but requires a reboot. 
  environment.systemPackages = with pkgs; [
    neovim # nvim
    bat # very useful for reading through large text dumps
    tree # display files
    iproute2 # show ip (ip addr) (run man ip for more)
    libgpiod # talk to gpio (only for cli testing, actually talk to gpio in code)
    can-utils # can
    perf # useful
    python314 # python
    stress-ng # see how this affects jitter
    fd # extremely fast find
    ripgrep # extremely fast grep
    xxd # useful, lets you view binary dumps
    hexyl # also lets you view binary dumps, try both and pick a favorite
    dtc # lets you inspect the device tree by decompiling files, as `dtc -I dtb -O dts <file.dtb>
  ];
  # I have my tmux set for alt, so this doesn't collide for me. It will for you unless you also set your tmux to alt.
  programs.tmux = {
    enable = true;
    extraConfig = ''
      bind C-i select-pane -t '{top-left}'
      bind C-o select-pane -t '{top-right}'
      bind C-j select-pane -t '{bottom-left}'
      bind C-k select-pane -t '{bottom-right}'
    '';
  };

  system.stateVersion = "25.11";
}
