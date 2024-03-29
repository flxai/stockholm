{ r6, w6, ... }:
{
  nets = {
    retiolum = {
      ip4.addr = "10.243.0.3";
      ip6.addr = r6 "4";
      aliases = [
        "echelon.r"
      ];
      tinc = {
        pubkey = ''
          -----BEGIN PUBLIC KEY-----
          MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEArxTpl0YvJWiF9cAYeAdp
          1gG18vrSeYDpmVCsZmxi2qyeWNM4JGSVPYoagyKHSDGH60xvktRh/1Zat+1hHR0A
          MAjDIENn9hAICQ8lafnm2v3+xzLNoTMJTYG3eba2MlJpAH0rYP0E5xBhQj9DCSAe
          UpEZWAwCKDCOmg/9h0gvs3kh0HopwjOE1IEzApgg05Yuhna96IATVdBAC7uF768V
          rJZNkQRvhetGxB459C58uMdcRK3degU6HMpZIXjJk6bqkzKBMm7C3lsAfaWulfez
          gavFSHC15NbHkz+fcVZNZReJhfTHP7k05xo5vYpDhszdUSjc3MtWBmk5v9zdS1pO
          c+20a1eurr1EPoYBqjQL0tLBwuQc2tN5XqJKVY5LGAnojAI6ktPKPLR6qZHC4Kna
          dgJ/S1BzHVxniYh3/rEzhXioneZ6oZgO+65WtsS42WAvh/53U/Q3chgI074Jssze
          ev09+zU8Xj0vX/7KpRKy5Vln6RGkQbKAIt7TZL5cJALswQDzcCO4WTv1X5KoG3+D
          KfTMfl9HzFsv59uHKlUqUguN5e8CLdmjgU1v2WvHBCw1PArIE8ZC0Tu2bMi5i9Vq
          GHxVn9O4Et5yPocyQtE4zOfGfqwR/yNa//Zs1b6DxQ73tq7rbBQaAzq7lxW6Ndbr
          43jjLL40ONdFxX7qW/DhT9MCAwEAAQ==
          -----END PUBLIC KEY-----
        '';
        pubkey_ed25519 = "LgJ7+/sq7t+Ym/DjJrWesIpUw1Lw7bxPi0XFHtsVWLB";
      };
    };
    wiregrill = {
      ip6.addr = w6 "3";
      aliases = [
        "echelon.w"
      ];
      wireguard.pubkey = ''
        SLdk0lph2rSFU+3dyrWDU1CT/oU+HPcOVYeGVIgDpEc=
      '';
    };
  };
  ssh.pubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIn+o0uCBSot254kZKlNepVKFcwDPdr8s6+lQmYGM3Hd ";
  syncthing.id = "TT4MBZS-YNDZUYO-Y6L4GOK-5IYUCXY-2RKFOSK-5SMZYSR-5QMOXSS-6DNJIAZ";
}
