{ config, lib, pkgs, ... }:

let
in

with builtins;
with lib;

{
  options = {
    services.urxvtd = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable urxvtd per user";
      };
      users = mkOption {
        type = types.listOf types.string;
        default = [];
        description = "users to run urxvtd for";
      };
      urxvtPackage = mkOption {
        type = types.package;
        default = pkgs.rxvt_unicode;
        description = "urxvt package to use";
      };
    };
  };

  config = 
    let
      cfg = config.services.urxvtd;
      users = cfg.users;
      urxvt = cfg.urxvtPackage;
      mkService = user: {
        description = "urxvt terminal daemon";
        wantedBy = [ "multi-user.target" ];
        restartIfChanged = false;
        path = [ pkgs.xlibs.xrdb ];
        environment = {
          DISPLAY = ":0";
          URXVT_PERL_LIB = "${urxvt}/lib/urxvt/perl";
        };
        serviceConfig = {
          Restart = "always";
          User = user;
          ExecStart = "${urxvt}/bin/urxvtd";
        };
      };
    in
      mkIf cfg.enable {
        environment.systemPackages = [ urxvt ];
        systemd.services = listToAttrs (map (u: { name = "${u}-urxvtd"; value = mkService u; }) users);
      };
}
