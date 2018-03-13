with import <stockholm/lib>;
host@{ name, secure ? false }: let
  builder = if getEnv "dummy_secrets" == "true"
              then "buildbot"
              else "nin";
  _file = <stockholm> + "/nin/1systems/${name}/source.nix";
  pkgs = import <nixpkgs> {
    overlays = map import [
      <stockholm/krebs/5pkgs>
    ];
  };
in
  evalSource (toString _file) {
    nixos-config.symlink = "stockholm/nin/1systems/${name}/config.nix";
    secrets.file = getAttr builder {
      buildbot = toString <stockholm/nin/6tests/dummysecrets>;
      nin = "/home/nin/secrets/${name}";
    };
    stockholm.file = toString <stockholm>;
    stockholm-version.pipe = "${pkgs.stockholm}/bin/get-version";
    nixpkgs = (import <stockholm/krebs/source.nix> host).nixpkgs;
  }
