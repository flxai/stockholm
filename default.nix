{ current-date
, current-host-name
, current-user-name
}:

let
  lib = import <nixpkgs/lib>;

  krebs-modules-path = ./krebs/3modules;
  krebs-pkgs-path = ./krebs/5pkgs;
  user-modules-path = ./. + "/${current-user-name}/3modules";
  user-pkgs-path = ./. + "/${current-user-name}/5pkgs";

  out =
    (lib.mapAttrs
      (k: v:
        if builtins.pathExists (./. + "/${k}/1systems")
          then mk-namespace (./. + "/${k}")
          else import (./. + "/${k}"))
      (lib.filterAttrs
        (k: v: !lib.hasPrefix "." k && v == "directory")
        (builtins.readDir ./.)));

  eval = path: import <nixpkgs/nixos/lib/eval-config.nix> {
    system = builtins.currentSystem;
    modules = [
      path
      krebs-modules-path
      user-modules-path
    ] ++ [
      ({ config, lib, pkgs, ... }@args: {
       _module.args.pkgs =
         (import krebs-pkgs-path args) //
         (import user-pkgs-path args);
      })
    ];
  };

  mk-namespace = path: mapNixDir mk-system (path + "/1systems");

  mk-system = path: rec {
    inherit (eval path) config options;
    system = config.system.build.toplevel;
    fetch = import ./krebs/0tools/fetch.nix { inherit config lib; };
  };

  mapNixDir = f: path: lib.mapAttrs (_: f) (nixDir path);

  nixDir = path:
    builtins.listToAttrs
      (catMaybes
        (lib.mapAttrsToList
          (k: v: {
            directory =
              let p = path + "/${k}/default.nix"; in
              if builtins.pathExists p
                then Just (lib.nameValuePair k p)
                else Nothing;
            regular =
              let p = path + "/${k}"; in
              if lib.hasSuffix ".nix" p
                then Just (lib.nameValuePair (lib.removeSuffix ".nix" k) p)
                else Nothing;
          }.${v} or Nothing)
          (builtins.readDir path)));

  # TODO move to lib
  Just = x: { type = "maybe"; value = x; };
  Nothing = { type = "maybe"; };
  isMaybe = x: builtins.typeOf x == "set" && x.type or false == "maybe";
  isJust = x: isMaybe x && builtins.hasAttr "value" x;
  fromJust = x: assert isJust x; x.value;
  catMaybes = xs: map fromJust (builtins.filter isJust xs);

in out
