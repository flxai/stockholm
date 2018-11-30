with import <stockholm/lib>;
{ config, lib, pkgs, ... }:
{
  imports = [
    <stockholm/lass>
    <stockholm/lass/2configs>
    <stockholm/lass/2configs/retiolum.nix>
  ];

  krebs.build.host = config.krebs.hosts.yellow;

  system.activationScripts.downloadFolder = ''
    mkdir -p /var/download
    chown download:download /var/download
    chmod 775 /var/download
  '';

  users.users.download = { uid = genid "download"; };
  users.groups.download.members = [ "transmission" ];
  users.users.transmission.group = mkForce "download";

  systemd.services.transmission.serviceConfig.bindsTo = [ "openvpn-nordvpn.service" ];
  services.transmission = {
    enable = true;
    settings = {
      download-dir = "/var/download/finished";
      incomplete-dir = "/var/download/incoming";
      incomplete-dir-enable = true;
      umask = "002";
      rpc-whitelist-enabled = false;
      rpc-host-whitelist-enabled = false;
    };
  };

  krebs.iptables = {
    enable = true;
    tables.filter.INPUT.rules = [
      { predicate = "-p tcp --dport 9091"; target = "ACCEPT"; }
      { predicate = "-p tcp --dport 51413"; target = "ACCEPT"; }
      { predicate = "-p udp --dport 51413"; target = "ACCEPT"; }
    ];
  };

  services.nginx.enable = true;
  services.openvpn.servers.nordvpn.config = ''
    client
    dev tun
    proto udp
    remote 82.102.16.229 1194
    resolv-retry infinite
    remote-random
    nobind
    tun-mtu 1500
    tun-mtu-extra 32
    mssfix 1450
    persist-key
    persist-tun
    ping 15
    ping-restart 0
    ping-timer-rem
    reneg-sec 0
    comp-lzo no

    explicit-exit-notify 3

    remote-cert-tls server

    #mute 10000
    auth-user-pass ${toString <secrets/nordvpn.txt>}

    verb 3
    pull
    fast-io
    cipher AES-256-CBC
    auth SHA512

    <ca>
    -----BEGIN CERTIFICATE-----
    MIIEyjCCA7KgAwIBAgIJANIxRSmgmjW6MA0GCSqGSIb3DQEBCwUAMIGeMQswCQYD
    VQQGEwJQQTELMAkGA1UECBMCUEExDzANBgNVBAcTBlBhbmFtYTEQMA4GA1UEChMH
    Tm9yZFZQTjEQMA4GA1UECxMHTm9yZFZQTjEaMBgGA1UEAxMRZGUyMjkubm9yZHZw
    bi5jb20xEDAOBgNVBCkTB05vcmRWUE4xHzAdBgkqhkiG9w0BCQEWEGNlcnRAbm9y
    ZHZwbi5jb20wHhcNMTcxMTIyMTQ1MTQ2WhcNMjcxMTIwMTQ1MTQ2WjCBnjELMAkG
    A1UEBhMCUEExCzAJBgNVBAgTAlBBMQ8wDQYDVQQHEwZQYW5hbWExEDAOBgNVBAoT
    B05vcmRWUE4xEDAOBgNVBAsTB05vcmRWUE4xGjAYBgNVBAMTEWRlMjI5Lm5vcmR2
    cG4uY29tMRAwDgYDVQQpEwdOb3JkVlBOMR8wHQYJKoZIhvcNAQkBFhBjZXJ0QG5v
    cmR2cG4uY29tMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAv++dfZlG
    UeFF2sGdXjbreygfo78Ujti6X2OiMDFnwgqrhELstumXl7WrFf5EzCYbVriNuUny
    mNCx3OxXxw49xvvg/KplX1CE3rKBNnzbeaxPmeyEeXe+NgA7rwOCbYPQJScFxK7X
    +D16ZShY25GyIG7hqFGML0Qz6gpZRGaHSd0Lc3wSgoLzGtsIg8hunhfi00dNqMBT
    ukCzgfIqbQUuqmOibsWnYvZoXoYKnbRL0Bj8IYvwvu4p2oBQpvM+JR4DC+rv52LI
    583Q6g3LebQ4JuQf8jgxvEEV4UL1CsUBqN3mcRpVUKJS3ijXmzEX9MfpBRcp1rBA
    VsiE4Mrk7PXhkwIDAQABo4IBBzCCAQMwHQYDVR0OBBYEFFIv1UuKN2NXaVjRNXDT
    Rs/+LT/9MIHTBgNVHSMEgcswgciAFFIv1UuKN2NXaVjRNXDTRs/+LT/9oYGkpIGh
    MIGeMQswCQYDVQQGEwJQQTELMAkGA1UECBMCUEExDzANBgNVBAcTBlBhbmFtYTEQ
    MA4GA1UEChMHTm9yZFZQTjEQMA4GA1UECxMHTm9yZFZQTjEaMBgGA1UEAxMRZGUy
    Mjkubm9yZHZwbi5jb20xEDAOBgNVBCkTB05vcmRWUE4xHzAdBgkqhkiG9w0BCQEW
    EGNlcnRAbm9yZHZwbi5jb22CCQDSMUUpoJo1ujAMBgNVHRMEBTADAQH/MA0GCSqG
    SIb3DQEBCwUAA4IBAQBf1vr93OIkIFehXOCXYFmAYai8/lK7OQH0SRMYdUPvADjQ
    e5tSDK5At2Ew9YLz96pcDhzLqtbQsRqjuqWKWs7DBZ8ZiJg1nVIXxE+C3ezSyuVW
    //DdqMeUD80/FZD5kPS2yJJOWfuBBMnaN8Nxb0BaJi9AKFHnfg6Zxqa/FSUPXFwB
    wH+zeymL2Dib2+ngvCm9VP3LyfIdvodEJ372H7eG8os8allUnkUzpVyGxI4pN/IB
    KROBRPKb+Aa5FWeWgEUHIr+hNrEMvcWfSvZAkSh680GScQeJh5Xb4RGMCW08tb4p
    lrojzCvC7OcFeUNW7Ayiuukx8rx/F4+IZ1yJGff9
    -----END CERTIFICATE-----
    </ca>
    key-direction 1
    <tls-auth>
    #
    # 2048 bit OpenVPN static key
    #
    -----BEGIN OpenVPN Static key V1-----
    49b2f54c6ee58d2d97331681bb577d55
    054f56d92b743c31e80b684de0388702
    ad3bf51088cd88f3fac7eb0729f2263c
    51d82a6eb7e2ed4ae6dfa65b1ac764d0
    b9dedf1379c1b29b36396d64cb6fd6b2
    e61f869f9a13001dadc02db171f04c4d
    c46d1132c1f31709e7b54a6eabae3ea8
    fbd2681363c185f4cb1be5aa42a27c31
    21db7b2187fd11c1acf224a0d5a44466
    b4b5a3cc34ec0227fe40007e8b379654
    f1e8e2b63c6b46ee7ab6f1bd82f57837
    92c209e8f25bc9ed493cb5c1d891ae72
    7f54f4693c5b20f136ca23e639fd8ea0
    865b4e22dd2af43e13e6b075f12427b2
    08af9ffd09c56baa694165f57fe2697a
    3377fa34aebcba587c79941d83deaf45
    -----END OpenVPN Static key V1-----
    </tls-auth>
  '';
}
