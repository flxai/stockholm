with import <stockholm/lib>;
host@{ name, secure ? false }: let
  builder = if getEnv "dummy_secrets" == "true"
              then "buildbot"
              else "shared";
  _file = <stockholm> + "/shared/1systems/${name}/source.nix";
in
  evalSource (toString _file) {
    nixos-config.symlink = "stockholm/shared/1systems/${name}/config.nix";
    secrets.file = getAttr builder {
      buildbot = toString <stockholm/shared/6tests/data/secrets>;
      lass = "${getEnv "HOME"}/secrets/krebs/${host.name}";
    };
    stockholm.file = toString <stockholm>;
    nixpkgs.git = {
      url = https://github.com/NixOS/nixpkgs;
      ref = "72c9ed78d0b1d9d5f531805ddf5bf06bfd447614"; # nixos-17.03 @ 2017-06-17
    };
  }
