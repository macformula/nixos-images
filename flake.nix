# thank you to https://wiki.nixos.org/wiki/NixOS_on_ARM/Raspberry_Pi#Installation
{
  inputs = {
    nixpkgs.url = "https://channels.nixos.org/nixos-unstable/nixexprs.tar.zst";
  };

  outputs = { nixpkgs, ... }: {
    nixosConfigurations.rpi4-image = nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
      modules = [
        "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
        ({ lib, ... }: {
          # Skip ZFS so it isn't pulled into the closure
          boot.supportedFilesystems.zfs = lib.mkForce false;
        })
        ./configuration.nix
      ];
    };
  };
}
