# can-hat.nix
{ lib, ... }: {
  # https://github.com/NixOS/nixos-hardware/blob/master/raspberry-pi/common/firmware.nix
  # https://mynixos.com/nixpkgs/option/boot.loader.generic-extlinux-compatible.useGenerationDeviceTree
  # seems like the pattern is useGenerationDeviceTree
  # if you ever want to decompile a .dtb, look at https://www.jeffgeerling.com/blog/2023/how-customize-dtb-device-tree-binary-on-raspberry-pi/
  # also, here is what actually processes the .dtb file: https://github.com/torvalds/linux/blob/master/drivers/of/overlay.c
  # https://elinux.org/Device_Tree_Reference <-- this is a good resource for embedded linux generally
  boot.loader.generic-extlinux-compatible.useGenerationDeviceTree = true;
  # https://mynixos.com/nixpkgs/options/hardware.deviceTree
  hardware.deviceTree.name = "broadcom/bcm2711-rpi-4-b.dtb";
  hardware.deviceTree.filter = lib.mkForce "*rpi-4-*.dtb";
  hardware.raspberry-pi."4".apply-overlays-dtmerge.enable = true;

  systemd.network.netdevs."40-vcan0".netdevConfig = {
    Kind = "vcan";
    Name = "vcan0";
  };

  systemd.network.networks."40-vcan0" = {
    matchConfig.Name = "vcan0";
    linkConfig.RequiredForOnline = "no";
  };

  # I don't love this solution https://mynixos.com/nixpkgs/option/hardware.deviceTree.overlays.
  # Adapted from infrastructure repo. This is also helpful, and pretty interesting: https://www.kernel.org/doc/html/latest/devicetree/usage-model.html
  # since we are not running raspios, most of this needs to be specified.
  hardware.deviceTree = {
    enable = true;
    overlays = [{
      name = "mcp2516-can0";
      dtsText = ''
        /dts-v1/;
        /plugin/;
        / {
          compatible = "brcm,bcm2711";
          fragment@0 {
            target = <&spi0>;
            __overlay__ { status = "okay"; };
          };
          fragment@1 {
            target = <&spidev0>;
            __overlay__ { status = "disabled"; };
          };
          fragment@2 {
            target = <&gpio>;
            __overlay__ {
              mcp2515_pins: mcp2515_pins {
                brcm,pins = <23>;
                brcm,function = <0>;
              };
            };
          };
          fragment@3 {
            target-path = "/";
            __overlay__ {
              can0_osc: can0-osc {
                compatible = "fixed-clock";
                #clock-cells = <0>;
                clock-frequency = <16000000>;
              };
            };
          };
          fragment@4 {
            target = <&spi0>;
            __overlay__ {
              #address-cells = <1>;
              #size-cells = <0>;
              mcp2515: mcp2515@0 {
                compatible = "microchip,mcp2515";
                reg = <0>;
                pinctrl-names = "default";
                pinctrl-0 = <&mcp2515_pins>;
                spi-max-frequency = <2000000>;
                interrupt-parent = <&gpio>;
                interrupts = <23 8>;
                clocks = <&can0_osc>;
              };
            };
          };
        };
      '';
    }];
  };
  boot.kernelModules = [ "mcp251x" "can_raw" "vcan"];
}