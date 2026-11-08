## Step 1
Nix build syntax can be confusing, the following basically specifies one attribute path.
'.' means this directory, '#' separates, and the rest is the path

```nix build .#nixosConfigurations.rpi4-image.config.system.build.sdImage```

Note that you need to set the following nix settings for a fast build on x86_64 NixOS (will still take a couple of minutes):

```
boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

nix.settings.extra-platforms = [ "aarch64-linux" ];
```

## Step 2
Find where your SD card is. Make sure it's the right one, verifying by size is usually safe.

```lsblk```
    
Images are .zst, so extract first. Then, copy to the SD card.

```zstdcat result/sd-image/*.img.zst | sudo dd of=/dev/<FILL THIS IN> bs=4M status=progress conv=fsync```


The best way to automate this script eventually will be to start it before you plug in the SD card, so that it can poll lsblk and when it sees a new block device, or a device with drastically changed size (card readers still register as devices even with no card, just with no size), it knows to write to it. Will have to unmount beforehand but that's fine, and eject after. This tool will benefit from a TUI.