{
  inputs = {
    nixpkgs.url = "https://channels.nixos.org/nixos-unstable/nixexprs.tar.zst";
    nixos-hardware = {
      url = "github:NixOS/nixos-hardware/master";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.racecar = {
        url = "github:macformula/racecar/353f479835308e5322d94e539065c0e1149f8b18";
      }
    };
  };

  outputs =
    { nixpkgs, nixos-hardware, ... }:
    let
      crossPkgs = nixpkgs.legacyPackages.x86_64-linux.pkgsCross.aarch64-multiplatform;
      crossKernel = crossPkgs.callPackage "${nixos-hardware}/raspberry-pi/common/kernel.nix" {
        rpiVersion = 4;
      };
    in
    {
      nixosConfigurations.rpi4 = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        modules = [
          "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
          nixos-hardware.nixosModules.raspberry-pi-4
          ./configuration.nix
          (
            { pkgs, lib, ... }:
            {
              boot.kernelPackages = pkgs.linuxPackagesFor crossKernel;
              boot.supportedFilesystems.zfs = lib.mkForce false;
              hardware.enableAllHardware = lib.mkForce false;
              hardware.raspberry-pi.firmware.uboot.enable = true;
            }
          )
        ];
      };
    };
}