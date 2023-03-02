{ config, lib, pkgs, ... }:

with import ../../lib { nixpkgs-lib = lib; };
let
  optionalAttr = name: value:
    if name != null then
      { ${name} = value; }
    else
      {};

  cfg = config.krebs.htgen;

  out = {
    options.krebs.htgen = api;
    config = imp;
  };

  api = mkOption {
    default = {};
    type = types.attrsOf (types.submodule ({ config, ... }: {
      options = {
        enable = mkEnableOption "krebs.htgen-${config._module.args.name}";

        name = mkOption {
          type = types.username;
          default = config._module.args.name;
        };

        package = mkOption {
          default = pkgs.htgen;
          type = types.package;
        };

        port = mkOption {
          type = types.uint;
        };

        script = mkOption {
          type = types.nullOr types.str;
          default = null;
        };

        scriptFile = mkOption {
          type = types.nullOr (types.either types.package types.pathname);
          default = null;
        };

        user = mkOption {
          type = types.user;
          default = {
            name = "htgen-${config.name}";
            home = "/var/lib/htgen-${config.name}";
          };
          defaultText = {
            name = "htgen-‹name›";
            home = "/var/lib/htgen-‹name›";
          };
        };
      };
    }));
  };
  imp = {

    systemd.services = mapAttrs' (name: htgen:
      nameValuePair "htgen-${name}" {
        wantedBy = [ "multi-user.target" ];
        after = [ "network.target" ];
        environment = {
          HTGEN_PORT = toString htgen.port;
        }
        // optionalAttr "HTGEN_SCRIPT" htgen.script
        // optionalAttr "HTGEN_SCRIPT_FILE" htgen.scriptFile
        ;
        serviceConfig = {
          SyslogIdentifier = "htgen";
          User = htgen.user.name;
          PrivateTmp = true;
          Restart = "always";
          ExecStart = "${htgen.package}/bin/htgen --serve";
        };
      }
    ) cfg;

    users.users = mapAttrs' (name: htgen:
      nameValuePair htgen.user.name {
        inherit (htgen.user) home name uid;
        group = htgen.user.name;
        createHome = true;
        isSystemUser = true;
      }
    ) cfg;

    users.groups = mapAttrs' (name: htgen:
      nameValuePair htgen.user.name {
        name = htgen.user.name;
        gid = htgen.user.uid;
      }
    ) cfg;

  };
in out
