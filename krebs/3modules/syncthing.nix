{ config, pkgs, ... }: with import <stockholm/lib>;

let

  cfg = config.krebs.syncthing;

  devices = mapAttrsToList (name: peer: {
    name = name;
    deviceID = peer.id;
    addresses = peer.addresses;
  }) cfg.peers;

  folders = map (folder: {
    inherit (folder) path id type;
    devices = map (peer: { deviceId = cfg.peers.${peer}.id; }) folder.peers;
    rescanIntervalS = folder.rescanInterval;
    fsWatcherEnabled = folder.watch;
    fsWatcherDelayS = folder.watchDelay;
    ignorePerms = folder.ignorePerms;
  }) cfg.folders;

  getApiKey = pkgs.writeDash "getAPIKey" ''
    ${pkgs.libxml2}/bin/xmllint \
      --xpath 'string(configuration/gui/apikey)'\
      ${config.services.syncthing.dataDir}/config.xml
  '';

  updateConfig = pkgs.writeDash "merge-syncthing-config" ''
    set -efu
    # wait for service to restart
    ${pkgs.untilport}/bin/untilport localhost 8384
    API_KEY=$(${getApiKey})
    CFG=$(${pkgs.curl}/bin/curl -Ss -H "X-API-Key: $API_KEY" localhost:8384/rest/system/config)
    echo "$CFG" | ${pkgs.jq}/bin/jq -s '.[] * {
      "devices": ${builtins.toJSON devices},
      "folders": ${builtins.toJSON folders}
    }' | ${pkgs.curl}/bin/curl -Ss -H "X-API-Key: $API_KEY" localhost:8384/rest/system/config -d @-
    ${pkgs.curl}/bin/curl -Ss -H "X-API-Key: $API_KEY" localhost:8384/rest/system/restart -X POST
  '';

in

{
  options.krebs.syncthing = {

    enable = mkEnableOption "syncthing-init";

    id = mkOption {
      type = types.str;
      default = config.krebs.build.host.name;
    };

    cert = mkOption {
      type = types.nullOr types.absolute-pathname;
      default = null;
    };

    key = mkOption {
      type = types.nullOr types.absolute-pathname;
      default = null;
    };

    peers = mkOption {
      default = {};
      type = types.attrsOf (types.submodule ({
        options = {

          # TODO make into addr + port submodule
          addresses = mkOption {
            type = types.listOf types.str;
            default = [];
          };

          #TODO check
          id = mkOption {
            type = types.str;
          };

        };
      }));
    };

    folders = mkOption {
      default = [];
      type = types.listOf (types.submodule ({ config, ... }: {
        options = {

          path = mkOption {
            type = types.absolute-pathname;
          };

          id = mkOption {
            type = types.str;
            default = config.path;
          };

          peers = mkOption {
            type = types.listOf types.str;
            default = [];
          };

          rescanInterval = mkOption {
            type = types.int;
            default = 3600;
          };

          type = mkOption {
            type = types.enum [ "sendreceive" "sendonly" "receiveonly" ];
            default = "sendreceive";
          };

          watch = mkOption {
            type = types.bool;
            default = true;
          };

          watchDelay = mkOption {
            type = types.int;
            default = 10;
          };

          ignorePerms = mkOption {
            type = types.bool;
            default = true;
          };

        };
      }));
    };
  };

  config = (mkIf cfg.enable) {

    systemd.services.syncthing = mkIf (cfg.cert != null || cfg.key != null) {
      preStart = ''
        ${optionalString (cfg.cert != null) ''
          cp ${toString cfg.cert} ${config.services.syncthing.dataDir}/cert.pem
          chown ${config.services.syncthing.user}:${config.services.syncthing.group} ${config.services.syncthing.dataDir}/cert.pem
          chmod 400 ${config.services.syncthing.dataDir}/cert.pem
        ''}
        ${optionalString (cfg.key != null) ''
          cp ${toString cfg.key} ${config.services.syncthing.dataDir}/key.pem
          chown ${config.services.syncthing.user}:${config.services.syncthing.group} ${config.services.syncthing.dataDir}/key.pem
          chmod 400 ${config.services.syncthing.dataDir}/key.pem
        ''}
      '';
    };

    systemd.services.syncthing-init = {
      after = [ "syncthing.service" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        User = config.services.syncthing.user;
        RemainAfterExit = true;
        Type = "oneshot";
        ExecStart = updateConfig;
      };
    };
  };
}