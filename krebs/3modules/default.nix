{ config, lib, ... }:

with import ../4lib { inherit lib; };
let
  cfg = config.krebs;

  out = {
    imports = [
      ./build
      ./exim-retiolum.nix
      ./exim-smarthost.nix
      ./github-hosts-sync.nix
      ./git.nix
      ./nginx.nix
      ./Reaktor.nix
      ./retiolum.nix
      ./urlwatch.nix
    ];
    options.krebs = api;
    config = mkIf cfg.enable imp;
  };

  api = {
    enable = mkEnableOption "krebs";

    dns = {
      providers = mkOption {
        # TODO with types; tree dns.label dns.provider, so we can merge.
        # Currently providers can only be merged if aliases occur just once.
        type = with types; attrsOf unspecified;
      };
    };

    hosts = mkOption {
      type = with types; attrsOf host;
    };

    users = mkOption {
      type = with types; attrsOf user;
    };

    # XXX is there a better place to define search-domain?
    # TODO search-domains :: listOf hostname
    search-domain = mkOption {
      type = types.hostname;
      default = "retiolum";
    };
    zone-head-config  = mkOption {
      type = with types; attrsOf str;
      description = ''
        The zone configuration head which is being used to create the
        zone files. The string for each key is pre-pended to the zone file.
        '';
        # TODO: configure the default somewhere else,
        # maybe use krebs.dns.providers
      default = {

        # github.io -> 192.30.252.154
        "krebsco.de" = ''
          $TTL 86400
          @ IN SOA dns19.ovh.net. tech.ovh.net. (2015052000 86400 3600 3600000 86400)
                                IN NS     ns19.ovh.net.
                                IN NS     dns19.ovh.net.
                                IN A      192.30.252.154
                                IN A      192.30.252.153
        '';
        };
    };
  };

  imp = mkMerge [
    { krebs = lass-imp; }
    { krebs = makefu-imp; }
    { krebs = tv-imp; }
    {
      krebs.dns.providers = {
        de.krebsco = "zones";
        internet = "hosts";
        retiolum = "hosts";
      };

      # XXX This overlaps with krebs.retiolum
      networking.extraHosts = concatStringsSep "\n" (flatten (
        mapAttrsToList (hostname: host:
          mapAttrsToList (netname: net:
            let
              aliases = longs ++ shorts;
              providers = dns.split-by-provider net.aliases cfg.dns.providers;
              longs = providers.hosts;
              shorts =
                map (removeSuffix ".${cfg.search-domain}")
                    (filter (hasSuffix ".${cfg.search-domain}")
                            longs);
            in
              map (addr: "${addr} ${toString aliases}") net.addrs
          ) (filterAttrs (name: host: host.aliases != []) host.nets)
        ) cfg.hosts
      ));

      # Implements environment.etc."zones/<zone-name>"
      environment.etc = let
        all-zones = foldAttrs (sum: current: sum + "\n" +current ) ""
          ([cfg.zone-head-config] ++ combined-hosts) ;
        combined-hosts = (mapAttrsToList (name: value: value.extraZones)  cfg.hosts );
      in lib.mapAttrs' (name: value: nameValuePair (("zones/" + name)) ({ text=value; })) all-zones;

      programs.ssh.knownHosts =
        mapAttrs
          (name: host: {
            hostNames =
              concatLists
                (mapAttrsToList
                  (net-name: net:
                    let
                      aliases = shorts ++ longs;
                      longs = net.aliases;
                      shorts =
                        map (removeSuffix ".${cfg.search-domain}")
                            (filter (hasSuffix ".${cfg.search-domain}")
                                    longs);
                      add-port = a:
                        if net.ssh.port != null
                          then "[${a}]:${toString net.ssh.port}"
                          else a;
                    in
                    aliases ++ map add-port net.addrs)
                  host.nets);

            publicKey = host.ssh.pubkey;
          })
          (filterAttrs (_: host: host.ssh.pubkey != null) cfg.hosts);
    }
  ];

  lass-imp = {
    hosts = addNames {
      echelon = {
        cores = 4;
        dc = "lass"; #dc = "cac";
        nets = rec {
          internet = {
            addrs4 = ["162.248.8.63"];
            aliases = [
              "echelon.internet"
            ];
          };
          retiolum = {
            via = internet;
            addrs4 = ["10.243.206.103"];
            addrs6 = ["42:941e:2816:35f4:5c5e:206b:3f0b:f763"];
            aliases = [
              "echelon.retiolum"
              "cgit.echelon.retiolum"
            ];
            tinc.pubkey = ''
              -----BEGIN RSA PUBLIC KEY-----
              MIIBCgKCAQEA92ybhDahtGybpAkUNlG5Elxw05MVY4Pg7yK0dQugB4nVq+pnmi78
              DOMeIciecMHmJM8n9UlUU0eWZVCgHeVd23d6J0hTHCv24p24uHEGGy7XlO/dPJ6A
              IjROYU0l8c03pipdJ3cDBx6riArSglwmZJ7xH/Iw0BUhRZrPqbtijY7EcG2wc+8K
              N9N9mBofVMl4EcBiDR/eecK+ro8OkeOmYPtYgFJLvxTYXiPIhOxMAlkOY2fpin/t
              cgFLUFuN4ag751XjjcNpVovVq95vdg+VhKrrNVWZjJt03owW81BzoryY6CD2kIPq
              UxK89zEdeYOUT7AxaT/5V5v41IvGFZxCzwIDAQAB
              -----END RSA PUBLIC KEY-----
            '';
          };
        };
      };
      cloudkrebs = {
        cores = 1;
        dc = "lass"; #dc = "cac";
        nets = rec {
          internet = {
            addrs4 = ["104.167.113.104"];
            aliases = [
              "cloudkrebs.internet"
            ];
          };
          retiolum = {
            via = internet;
            addrs4 = ["10.243.206.102"];
            addrs6 = ["42:941e:2816:35f4:5c5e:206b:3f0b:f762"];
            aliases = [
              "cloudkrebs.retiolum"
              "cgit.cloudkrebs.retiolum"
            ];
            tinc.pubkey = ''
              -----BEGIN RSA PUBLIC KEY-----
              MIIBCgKCAQEAttUygCu7G6lIA9y+9rfTpLKIy2UgNDglUVoKZYLs8JPjtAtQVbtA
              OcWwwPc8ijLQvwJWa8e/shqSzSIrtOe+HJbRGdXLdBLtOuLKpz+ZFHcS+95RS5aF
              QTehg+QY7pvhbrrwKX936tkMR568suTQG6C8qNC/5jWYO/wIxFMhnQ2iRRKQOq1v
              3aGGPC16KeXKVioY9KoV98S3n1rZW1JK07CIsZU4qb5txtLlW6FplJ7UmhVku1WC
              sgOOj9yi6Zk1t8R2Pwv9gxa3Hc270voj5U+I2hgLV/LjheE8yhQgYHEA4vXerPdO
              TGSATlSmMtE2NYGrKsLM7pKn286aSpXinwIDAQAB
              -----END RSA PUBLIC KEY-----
            '';
          };
        };
      };
      uriel = {
        cores = 1;
        dc = "lass";
        nets = rec {
          retiolum = {
            addrs4 = ["10.243.81.176"];
            addrs6 = ["42:dc25:60cf:94ef:759b:d2b6:98a9:2e56"];
            aliases = [
              "uriel.retiolum"
              "cgit.uriel.retiolum"
            ];
            tinc.pubkey = ''
              -----BEGIN RSA PUBLIC KEY-----
              MIIBCgKCAQEAzw0pvoEmqeqiZrzSOPH0IT99gr1rrvMZbvabXoU4MAiVgGoGrkmR
              duJkk8Fj12ftMc+Of1gnwDkFhRcfAKOeH1RSc4CTircWVq99WyecTwEZoaR/goQb
              MND022kIBoG6NQNxv1Y5I1B/h7hfloMFEPym9oFtOAXoGhBY2vVl4g64NNz+RLME
              m1RipLXKANAh6LRNPGPQCUYX4TVY2ZJVxM3CM1XdomUAdOYXJmWFyUg9NcIKaacx
              uRrmuy7J9yFBcihZX5Y7NV361kINrpRmZYxJRf9cr0hb5EkJJ7bMIKQMEFQ5RnYo
              u7MPGKD7aNHa6hLLCeIfJ5u0igVmSLh3pwIDAQAB
              -----END RSA PUBLIC KEY-----
            '';
          };
        };
        secure = true;
      };
      mors = {
        cores = 2;
        dc = "lass";
        nets = rec {
          retiolum = {
            addrs4 = ["10.243.0.2"];
            addrs6 = ["42:0:0:0:0:0:0:dea7"];
            aliases = [
              "mors.retiolum"
              "cgit.mors.retiolum"
            ];
            tinc.pubkey = ''
              -----BEGIN RSA PUBLIC KEY-----
              MIIBCgKCAQEAsj1PCibKOfF68gmFQ+wwyfhUWpqKqpznrJX1dZ+daae7l7nBHvsE
              H0QwkiMmk3aZy1beq3quM6gX13aT+/wMfWnLyuvT11T5C9JEf/IS91STpM2BRN+R
              +P/DhbuDcW4UsdEe6uwQDGEJbXRN5ZA7GI0bmcYcwHJ9SQmW5v7P9Z3oZ+09hMD+
              1cZ3HkPN7weSdMLMPpUpmzCsI92cXGW0xRC4iBEt1ZeBwjkLCRsBFBGcUMuKWwVa
              9sovca0q3DUar+kikEKVrVy26rZUlGuBLobMetDGioSawWkRSxVlfZvTHjAK5JzU
              O6y6hj0yQ1sp6W2JjU8ntDHf63aM71dB9QIDAQAB
              -----END RSA PUBLIC KEY-----
            '';
          };
        };
        secure = true;
      };

    };
    users = addNames {
      lass = {
        pubkey = readFile ../Zpubkeys/lass.ssh.pub;
        mail = "lass@mors.retiolum";
      };
      uriel = {
        pubkey = readFile ../Zpubkeys/uriel.ssh.pub;
        mail = "lass@uriel.retiolum";
      };
    };
  };

  makefu-imp = {
    hosts = addNames {
      pnp = {
        cores = 1;
        dc = "makefu"; #vm on 'omo'
        nets = {
          retiolum = {
            addrs4 = ["10.243.0.210"];
            addrs6 = ["42:f9f1:0000:0000:0000:0000:0000:0001"];
            aliases = [
              "pnp.retiolum"
              "cgit.pnp.retiolum"
            ];
            tinc.pubkey = ''
              -----BEGIN RSA PUBLIC KEY-----
              MIIBCgKCAQEAugkgEK4iy2C5+VZHwhjj/q3IOhhazE3TYHuipz37KxHWX8ZbjH+g
              Ewtm79dVysujAOX8ZqV8nD8JgDAvkIZDp8FCIK0/rgckhpTsy1HVlHxa7ECrOS8V
              pGz4xOxgcPFRbv5H2coHtbnfQc4GdA5fcNedQ3BP3T2Tn7n/dbbVs30bOP5V0EMR
              SqZwNmtqaDQxOvjpPg9EoHvAYTevrpbbIst9UzCyvmNli9R+SsiDrzEPgB7zOc4T
              TG12MT+XQr6JUu4jPpzdhb6H/36V6ADCIkBjzWh0iSfWGiFDQFinD+YSWbA1NOTr
              Qtd1I3Ov+He7uc2Z719mb0Og2kCGnCnPIwIDAQAB
              -----END RSA PUBLIC KEY-----
              '';
          };
        };
      };
      tsp = {
        cores = 1;
        dc = "makefu"; #x200
        nets = {
          retiolum = {
            addrs4 = ["10.243.0.212"];
            addrs6 = ["42:f9f1:0000:0000:0000:0000:0000:0002"];
            aliases = [
              "tsp.retiolum"
            ];
            tinc.pubkey = ''
              -----BEGIN RSA PUBLIC KEY-----
              MIICCgKCAgEAwW+RjRcp3uarkfXZ+FcCYY2GFcfI595GDpLRuiS/YQAB3JZEirHi
              HFhDJN80fZ9qHqtq9Af462xSx+cIb282TxAqCM1Z9buipOcYTYo0m8xIqkT10dB3
              mR87B+Ed1H6G3J6isdwEb9ZMegyGIIeyR53FJQYMZXjxdJbAmGMDKqjZSk1D5mo+
              n5Vx3lGzTuDy84VyphfO2ypG48RHCxHUAx4Yt3o84LKoiy/y5E66jaowCOjZ6SqG
              R0cymuhoBhMIk2xAXk0Qn7MZ1AOm9N7Wru7FXyoLc7B3+Gb0/8jXOJciysTG7+Gr
              Txza6fJvq2FaH8iBnfezSELmicIYhc8Ynlq4xElcHhQEmRTQavVe/LDhJ0i6xJSi
              aOu0njnK+9xK+MyDkB7n8dO1Iwnn7aG4n3CjVBB4BDO08lrovD3zdpDX0xhWgPRo
              ReOJ3heRO/HsVpzxKlqraKWoHuOXXcREfU9cj3F6CRd0ECOhqtFMEr6TnuSc8GaE
              KCKxY1oN45NbEFOCv2XKd2wEZFH37LFO6xxzSRr1DbVuKRYIPjtOiFKpwN1TIT8v
              XGzTT4TJpBGnq0jfhFwhVjfCjLuGj29MCkvg0nqObQ07qYrjdQI4W1GnGOuyXkvQ
              teyxjUXYbp0doTGxKvQaTWp+JapeEaJPN2MDOhrRFjPrzgo3aW9+97UCAwEAAQ==
              -----END RSA PUBLIC KEY-----
              '';
          };
        };
      };
      pornocauster = {
        cores = 2;
        dc = "makefu"; #x220
        nets = {
          retiolum = {
            addrs4 = ["10.243.0.91"];
            addrs6 = ["42:0b2c:d90e:e717:03dc:9ac1:7c30:a4db"];
            aliases = [
              "pornocauster.retiolum"
            ];
            tinc.pubkey = ''
              -----BEGIN RSA PUBLIC KEY-----
              MIICCgKCAgEAwW+RjRcp3uarkfXZ+FcCYY2GFcfI595GDpLRuiS/YQAB3JZEirHi
              HFhDJN80fZ9qHqtq9Af462xSx+cIb282TxAqCM1Z9buipOcYTYo0m8xIqkT10dB3
              mR87B+Ed1H6G3J6isdwEb9ZMegyGIIeyR53FJQYMZXjxdJbAmGMDKqjZSk1D5mo+
              n5Vx3lGzTuDy84VyphfO2ypG48RHCxHUAx4Yt3o84LKoiy/y5E66jaowCOjZ6SqG
              R0cymuhoBhMIk2xAXk0Qn7MZ1AOm9N7Wru7FXyoLc7B3+Gb0/8jXOJciysTG7+Gr
              Txza6fJvq2FaH8iBnfezSELmicIYhc8Ynlq4xElcHhQEmRTQavVe/LDhJ0i6xJSi
              aOu0njnK+9xK+MyDkB7n8dO1Iwnn7aG4n3CjVBB4BDO08lrovD3zdpDX0xhWgPRo
              ReOJ3heRO/HsVpzxKlqraKWoHuOXXcREfU9cj3F6CRd0ECOhqtFMEr6TnuSc8GaE
              KCKxY1oN45NbEFOCv2XKd2wEZFH37LFO6xxzSRr1DbVuKRYIPjtOiFKpwN1TIT8v
              XGzTT4TJpBGnq0jfhFwhVjfCjLuGj29MCkvg0nqObQ07qYrjdQI4W1GnGOuyXkvQ
              teyxjUXYbp0doTGxKvQaTWp+JapeEaJPN2MDOhrRFjPrzgo3aW9+97UCAwEAAQ==
              -----END RSA PUBLIC KEY-----
              '';
          };
        };
      };
      flap = rec {
        cores = 1;
        dc = "cac"; #vps

        extraZones = {
          "krebsco.de" = ''
            mediengewitter    IN A      ${elemAt nets.internet.addrs4 0}
            flap              IN A      ${elemAt nets.internet.addrs4 0}'';
        };
        nets = {
          internet = {
            addrs4 = ["162.248.11.162"];
            aliases = [
              "flap.internet"
            ];
          };
          retiolum = {
            addrs4 = ["10.243.211.172"];
            addrs6 = ["42:472a:3d01:bbe4:4425:567e:592b:065d"];
            aliases = [
              "flap.retiolum"
            ];
            tinc.pubkey = ''
              -----BEGIN RSA PUBLIC KEY-----
              MIIBCgKCAQEAwtLD+sgTQGO+eh2Ipq2r54J1I0byvfkaTBeBwhtUmWst+lUQUoGy
              2fGReRYsb4ThDLeyK439jZuQBeXSc5r2g0IHBJCSWj3pVxc1HRTa8LASY7QuprQM
              8rSQa2XUtx/KpfM2eVX0yIvLuPTxBoOf/AwklIf+NmL7WCfN7sfZssoakD5a1LGn
              3EtZ2M/4GyoXJy34+B8v7LugeClnW3WDqUBZnNfUnsNWvoldMucxsl4fAhvEehrL
              hGgQMjHFOdKaLyatZOx6Pq4jAna+kiJoq3mVDsB4rcjLuz8XkAUZmVpe5fXAG4hr
              Ig8l/SI6ilu0zCWNSJ/v3wUzksm0P9AJkwIDAQAB
              -----END RSA PUBLIC KEY-----
              '';
          };
        };
      };
      pigstarter = rec {
        cores = 1;
        dc = "frontrange"; #vps

        extraZones = {
          "krebsco.de" = ''
                              IN MX 10  mx42
            euer              IN MX 1   aspmx.l.google.com.
            io                IN NS     pigstarter.krebsco.de.
            euer              IN A      ${elemAt nets.internet.addrs4 0}
            pigstarter        IN A      ${elemAt nets.internet.addrs4 0}
            conf              IN A      ${elemAt nets.internet.addrs4 0}
            gold              IN A      ${elemAt nets.internet.addrs4 0}
            graph             IN A      ${elemAt nets.internet.addrs4 0}
            tinc              IN A      ${elemAt nets.internet.addrs4 0}
            boot              IN A      ${elemAt nets.internet.addrs4 0}
            mx42              IN A      ${elemAt nets.internet.addrs4 0}'';
        };
        nets = {
          internet = {
            addrs4 = ["192.40.56.122"];
            addrs6 = ["2604:2880::841f:72c"];
            aliases = [
              "pigstarter.internet"
            ];
          };
          retiolum = {
            addrs4 = ["10.243.0.153"];
            addrs6 = ["42:9143:b4c0:f981:6030:7aa2:8bc5:4110"];
            aliases = [
              "pigstarter.retiolum"
            ];
            tinc.pubkey = ''
              -----BEGIN RSA PUBLIC KEY-----
              MIIBCgKCAQEA/efJuJRLUIZROe3QE8WYTD/zyNGRh9I2/yw+5It9HSNVDMIOV1FZ
              9PaspsC+YQSBUQRN8SJ95G4RM6TIn/+ei7LiUYsf1Ik+uEOpP5EPthXqvdJEeswv
              3QFwbpBeOMNdvmGvQLeR1uJKVyf39iep1wWGOSO1sLtUA+skUuN38QKc1BPASzFG
              4ATM6rd2Tkt8+9hCeoePJdLr3pXat9BBuQIxImgx7m5EP02SH1ndb2wttQeAi9cE
              DdJadpzOcEgFatzXP3SoKVV9loRHz5HhV4WtAqBIkDvgjj2j+NnXolAUY25Ix+kv
              sfqfIw5aNLoIX4kDhuDEVBIyoc7/ofSbkQIDAQAB
              -----END RSA PUBLIC KEY-----
              '';
          };
        };
      };
      gum = rec {
        cores = 1;
        dc = "online.net"; #root-server

        extraZones = {
          "krebsco.de" = ''
            omo               IN A      ${elemAt nets.internet.addrs4 0}
            gum               IN A      ${elemAt nets.internet.addrs4 0}
            paste             IN A      ${elemAt nets.internet.addrs4 0}'';
        };
        nets = {
          internet = {
            addrs4 = ["195.154.108.70"];
            aliases = [
              "gum.internet"
            ];
          };
          retiolum = {
            addrs4 = ["10.243.0.211"];
            addrs6 = ["42:f9f0:0000:0000:0000:0000:0000:70d2"];
            aliases = [
              "gum.retiolum"
            ];
            tinc.pubkey = ''
              -----BEGIN RSA PUBLIC KEY-----
              MIIBCgKCAQEAvgvzx3rT/3zLuCkzXk1ZkYBkG4lltxrLOLNivohw2XAzrYDIw/ZY
              BTDDcD424EkNOF6g/3tIRWqvVGZ1u12WQ9A/R+2F7i1SsaE4nTxdNlQ5rjy80gO3
              i1ZubMkTGwd1OYjJytYdcMTwM9V9/8QYFiiWqh77Xxu/FhY6PcQqwHxM7SMyZCJ7
              09gtZuR16ngKnKfo2tw6C3hHQtWCfORVbWQq5cmGzCb4sdIKow5BxUC855MulNsS
              u5l+G8wX+UbDI85VSDAtOP4QaSFzLL+U0aaDAmq0NO1QiODJoCo0iPhULZQTFZUa
              OMDYHHfqzluEI7n8ENI4WwchDXH+MstsgwIDAQAB
              -----END RSA PUBLIC KEY-----
              '';
          };
        };
      };
    };
    users = addNames {
      makefu = {
        mail = "makefu@pornocauster.retiolum";
        pubkey = readFile ../Zpubkeys/makefu_arch.ssh.pub;
      };
    };
  };

  tv-imp = {
    dns.providers = {
      de.viljetic = "regfish";
    };
    hosts = addNames {
      cd = rec {
        cores = 2;
        dc = "tv"; #dc = "cac";
        extraZones = {
          "krebsco.de" = ''
            mx23          IN A ${elemAt nets.internet.addrs4 0}
            cd            IN A ${elemAt nets.internet.addrs4 0}
            krebsco.de.   IN MX 5 mx23'';
        };
        nets = rec {
          internet = {
            addrs4 = ["162.219.7.216"];
            aliases = [
              "cd.internet"
              "cd.viljetic.de"
              "cgit.cd.viljetic.de"
              "cd.krebsco.de"
            ];
            ssh.port = 11423;
          };
          retiolum = {
            via = internet;
            addrs4 = ["10.243.113.222"];
            addrs6 = ["42:4522:25f8:36bb:8ccb:0150:231a:2af3"];
            aliases = [
              "cd.retiolum"
              "cgit.cd.retiolum"
            ];
            tinc.pubkey = ''
              -----BEGIN RSA PUBLIC KEY-----
              MIICCgKCAgEAvmCBVNKT/Su4v9nl/Nm3STPo5QxWPg7xEkzIs3Oh39BS8+r6/7UQ
              rebib7mczb+ebZd+Rg2yFoGrWO8cmM0VcLy5bYRMK7in8XroLEjWecNNM4TRfNR4
              e53+LhcPdkxo0A3/D+yiut+A2Mkqe+4VXDm/JhAiAYkZTn7jUtj00Atrc7CWW1gN
              sP3jIgv4+CGftdSYOB4dm699B7OD9XDLci2kOaFqFl4cjDYUok03G0AduUlRx10v
              CKbKOTIdm8C36A902/3ms+Hyzkruu+VagGIZuPSwqXHJPCu7Ju+jarKQstMmpQi0
              PubweWDL0o/Dfz2qT3DuL4xDecIvGE6kv3m41hHJYiK+2/azTSehyPFbsVbL7w0V
              LgKN3usnZNcpTsBWxRGT7nMFSnX2FLDu7d9OfCuaXYxHVFLZaNrpccOq8NF/7Hbk
              DDW81W7CvLyJDlp0WLnAawSOGTUTPoYv/2wAapJ89i8QGCueGvEc6o2EcnBVMFEW
              ejWTQzyD816f4RsplnrRqLVlIMbr9Q/n5TvlgjjhX7IMEfMy4+7qLGRQkNbFzgwK
              jxNG2fFSCjOEQitm0gAtx7QRIyvYr6c7/xiHz4AwxYzBmvQsL/OK57NO4+Krwgj5
              Vk8TQ2jGO7J4bB38zaxK+Lrtfl8i1AK1171JqFMhOc34JSJ7T4LWDMECAwEAAQ==
              -----END RSA PUBLIC KEY-----
            '';
          };
        };
        ssh.pubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOd/HqZIO9Trn3eycl23GZAz21HQCISaVNfNyaLSQvJ6";
      };
      mkdir = rec {
        cores = 1;
        dc = "tv"; #dc = "cac";
        infest.addr = head nets.internet.addrs4;
        nets = rec {
          internet = {
            addrs4 = ["104.233.84.102"];
            aliases = [
              "mkdir.internet"
            ];
          };
          retiolum = {
            via = internet;
            addrs4 = ["10.243.113.223"];
            addrs6 = ["42:4522:25f8:36bb:8ccb:0150:231a:2af4"];
            aliases = [
              "mkdir.retiolum"
              "cgit.mkdir.retiolum"
            ];
            tinc.pubkey = ''
              -----BEGIN RSA PUBLIC KEY-----
              MIIBCgKCAQEAuyfM+3od75zOYXqnqRMAt+yp/4z/vC3vSWdjUvEmCuM23c5BOBw+
              dKqbWoSPTzOuaQ0szdL7a6YxT+poSUXd/i3pPz59KgCl192rd1pZoJKgvoluITev
              voYSP9rFQOUrustfDb9qKW/ZY95cwdCvypo7Vf4ghxwDCnlmyCGz7qXTJMLydNKF
              2PH9KiY4suv15sCg/zisu+q0ZYQXUc1TcgpoIYBOftDunOJoNdbti+XjwWdjGmJZ
              Bn4GelsrrpwJFvfDmouHUe8GsD7nTgbZFtiJbKfCEiK16N0Q0d0ZFHhAV2nPjsk2
              3JhG4n9vxATBkO82f7RLrcrhkx9cbLfN3wIDAQAB
              -----END RSA PUBLIC KEY-----
            '';
          };
        };
        ssh.privkey = <secrets/ssh.id_ed25519>;
        ssh.pubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICuShEqU0Cdm7KCaMD5x1D6mgj+cr7qoqbzFJDKoBbbw";
      };
      ire = {
        nets = {
          internet = {
            addrs4 = ["198.147.22.115"];
            ssh.port = 11423;
          };
          retiolum = {
            addrs4 = ["10.243.231.66"];
            addrs6 = ["42:b912:0f42:a82d:0d27:8610:e89b:490c"];
            aliases = [
              "ire.retiolum"
            ];
            tinc.pubkey = ''
              -----BEGIN RSA PUBLIC KEY-----
              MIIBCgKCAQEAwofjmP/XBf5pwsJlWklkSzI+Bo0I0B9ONc7/j+zpbmMRkwbWk4X7
              rVLt1cWvTY15ujg2u8l0o6OgEbIkc6rslkD603fv1sEAd0KOv7iKLgRpE9qfSvAt
              6YpiSv+mxEMTpH0g36OmBfOJ10uT+iHDB/FfxmgGJx//jdJADzLjjWC6ID+iGkGU
              1Sf+yHXF7HRmQ29Yak8LYVCJpGC5bQfWIMSL5lujLq4NchY2d+NZDkuvh42Ayr0K
              LPflnPBQ3XnKHKtSsnFR2vaP6q+d3Opsq/kzBnAkjL26jEuFK1v7P/HhNhJoPzwu
              nKKWj/W/k448ce374k5ycjvKm0c6baAC/wIDAQAB
              -----END RSA PUBLIC KEY-----
            '';
            ssh.port = 11423;
          };
        };
        ssh.pubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBaMjBJ/BfYlHjyn5CO0xzFNaQ0LPvMP3W9UlOs1OxGY";
      };
      nomic = {
        cores = 2;
        dc = "tv"; #dc = "gg23";
        nets = rec {
          retiolum = {
            addrs4 = ["10.243.0.110"];
            addrs6 = ["42:02d5:733f:d6da:c0f5:2bb7:2b18:09ec"];
            aliases = [
              "nomic.retiolum"
              "cgit.nomic.retiolum"
            ];
            tinc.pubkey = ''
              -----BEGIN RSA PUBLIC KEY-----
              MIIBCgKCAQEAwb8Yk/YRc17g2J9n960p6j4W/l559OPyuMPdGJ4DmCm3WNQtxoa+
              qTFUiDiI85BcmfqnSeddLG8zTC2XnSlIvCRMJ9oKzppFM4PX4OTAaJZVE5WyCQhw
              Kd4tHVdoQgJW5yFepmT9IUmHqkxXJ0R2W93l2eSZNOcnFvFn0ooiAlRi4zAiHClu
              5Mz80Sc2rvez+n9wtC2D06aYjP23pHYld2xighHR9SUqX1dFzgSXNSoWWCcgNp2a
              OKcM8LzxLV7MTMZFOJCJndZ77e4LsUvxhQFP6nyKZWg30PC0zufZsuN5o2xsWSlA
              Wi9sMB1AUR6mZrxgcgTFpUjbjbLQf+36CwIDAQAB
              -----END RSA PUBLIC KEY-----
            '';
          };
        };
        secure = true;
        ssh.pubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILn7C3LxAs9kUynENdRNgQs4qjrhNDfXzlHTpVJt6e09";
      };
      rmdir = rec {
        cores = 1;
        dc = "tv"; #dc = "cac";
        infest.addr = head nets.internet.addrs4;
        nets = rec {
          internet = {
            addrs4 = ["104.233.84.70"];
            aliases = [
              "rmdir.internet"
            ];
          };
          retiolum = {
            via = internet;
            addrs4 = ["10.243.113.224"];
            addrs6 = ["42:4522:25f8:36bb:8ccb:0150:231a:2af5"];
            aliases = [
              "rmdir.retiolum"
              "cgit.rmdir.retiolum"
            ];
            tinc.pubkey = ''
              -----BEGIN RSA PUBLIC KEY-----
              MIIBCgKCAQEA+twy4obSbJdmZLfBoe9YYeyoDnXkO/WPa2D6Eh6jXrWk5fbhBjRf
              i3EAQfLiXXFJX3E8V8YvJyazXklI19jJtCLDiu/F5kgJJfyAkWHH+a/hcg7qllDM
              Xx2CvS/nCbs+p48/VLO6zLC7b1oHu3K/ob5M5bwPK6j9NEDIL5qYiM5PQzV6zryz
              hS9E/+l8Z+UUpYcfS3bRovXJAerB4txc/gD3Xmptq1zk53yn1kJFYfVlwyyz+NEF
              59JZj2PDrvWoG0kx/QjiNurs6XfdnyHe/gP3rmSTrihKFVuA3cZM62sDR4FcaeWH
              SnKSp02pqjBOjC/dOK97nXpKLJgNH046owIDAQAB
              -----END RSA PUBLIC KEY-----
            '';
          };
        };
        ssh.pubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFGniQyABsMNSFTKAxJgxZlLrWfexUt+vhZ3p2hpBl4J";
      };
      wu = {
        cores = 4;
        # TODO wu is mobile, so dc means "home data center"
        dc = "tv"; #dc = "gg23";
        nets = {
          retiolum = {
            addrs4 = ["10.243.13.37"];
            addrs6 = ["42:0:0:0:0:0:0:1337"];
            aliases = [
              "wu.retiolum"
            ];
            tinc.pubkey = ''
              -----BEGIN RSA PUBLIC KEY-----
              MIIBCgKCAQEArDvU0cuBsVqTjCX2TlWL4XHSy4qSjUhjrDvUPZSKTVN7x6OENCUn
              M27g9H7j4/Jw/8IHoJLiKnXHavOoc9UJM+P9Fla/4TTVADr69UDSnLgH+wGiHcEg
              GxPkb2jt0Z8zcpD6Fusj1ATs3sssaLHTHvg1D0LylEWA3cI4WPP13v23PkyUENQT
              KpSWfR+obqDl38Q7LuFi6dH9ruyvqK+4syddrBwjPXrcNxcGL9QbDn7+foRNiWw4
              4CE5z25oGG2iWMShI7fe3ji/fMUAl7DSOOrHVVG9eMtpzy+uI8veOHrdTax4oKik
              AFGCrMIov3F0GIeu3nDlrTIZPZDTodbFKQIDAQAB
              -----END RSA PUBLIC KEY-----
            '';
          };
        };
        secure = true;
        ssh.pubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIcJvu8JDVzObLUtlAQg9qVugthKSfitwCljuJ5liyHa";
      };
      xu = {
        cores = 4;
        # TODO xu is mobile, so dc means "home data center"
        dc = "tv"; #dc = "gg23";
        nets = {
          retiolum = {
            addrs4 = ["10.243.13.38"];
            addrs6 = ["42:0:0:0:0:0:0:1338"];
            aliases = [
              "xu.retiolum"
            ];
            tinc.pubkey = ''
              -----BEGIN RSA PUBLIC KEY-----
              MIIBCgKCAQEAl3l7IWbfbkVgaJFM3s9g2UCh2rmqoTba16Of7NNWMj05L/hIkUsQ
              uc43/QzidWh/4gEaq5MQ7JpLyzVBQYRJkNlPRF/Z07KdLBskAZCjDYdYue9BrziX
              8s2Irs2+FNbCK2LqtrPhbcXQJvixsk6vjl2OBpWTDUcDEsk+D1YQilxdtyUzCUkw
              mmRo/mzNsLZsYlSgZ6El/ZLkRdtexAzGxJ0DrukpDR0uqXXkp7jUaxRCZ+Cwanvj
              4I1Hu5aHzWB7KJ1SIvpX3a4f+mun1gh3TPqWP5PUqJok1PSuScz6P2UGaLZZyH63
              4o+9nGJPuzb9bpMVRaVGtKXd39jwY7mbqwIDAQAB
              -----END RSA PUBLIC KEY-----
            '';
          };
        };
        secure = true;
        ssh.pubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID554niVFWomJjuSuQoiCdMUYrCFPpPzQuaoXXYYDxlw";
      };
    };
    users = addNames {
      mv = {
        mail = "mv@cd.retiolum";
        pubkey = readFile ../Zpubkeys/mv_vod.ssh.pub;
      };
      tv = {
        mail = "tv@wu.retiolum";
        pubkey = readFile ../Zpubkeys/tv_wu.ssh.pub;
      };
    };
  };

in
out
