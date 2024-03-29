{ config, lib, pkgs, ... }:
# TODO test `alsactl init` after suspend to reinit mic
{
  security.rtkit.enable = true;

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  environment.systemPackages = with pkgs; [
    alsa-utils
    pulseaudio
    ponymix
  ];

  services.pipewire = {
    enable = true;
    systemWide = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  systemd.services.wireplumber = {
    environment = {
      HOME = "/var/lib/wireplumber";
      DISPLAY = ":0";
    };
    path = [
      pkgs.dbus
    ];
    serviceConfig.StateDirectory = "wireplumber";
  };
}
