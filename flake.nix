{
  description = "Take all the computers hostage, they'll love you";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:NixOS/nixpkgs";
    nix-writers.url = "git+https://cgit.krebsco.de/nix-writers";
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    flake-utils,
    nix-writers,
  }:
    {
      nixosModules = let
      in {
        htgen = {config, lib, pkgs, ...}: import krebs/3modules/htgen.nix {
          inherit config lib;
          pkgs = import nixpkgs {
            inherit (config.nixpkgs) system;
            overlays = [
              nix-writers.overlays.default
              (self: super: {
                htgen = inputs.self.packages.${config.nixpkgs.system}.htgen;
              })
            ];
          };
        };
        power-action = {config, lib, pkgs, ...}: import krebs/3modules/power-action.nix {
          inherit config lib;
          pkgs = import nixpkgs {
            inherit (config.nixpkgs) system;
            overlays = [
              nix-writers.overlays.default
            ];
          };
        };
      };
    }
    // flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {
        inherit system;
        overlays = [nix-writers.overlays.default];
      };
    in {
      packages = {
        cyberlocker-tools = pkgs.callPackage krebs/5pkgs/simple/cyberlocker-tools {};
        hc = pkgs.callPackage tv/5pkgs/simple/hc.nix {};
        dic = pkgs.callPackage krebs/5pkgs/simple/dic {};
        htgen = pkgs.callPackage krebs/5pkgs/simple/htgen {};
        kpaste = pkgs.callPackage krebs/5pkgs/simple/kpaste {};
        untilport = pkgs.callPackage krebs/5pkgs/simple/untilport {};
        weechat-declarative = pkgs.callPackage krebs/5pkgs/simple/weechat-declarative {};
      };
    });
}
