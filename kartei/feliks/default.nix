{ config, ... }: let
  lib = import ../../lib;
in {
  users.feliks = {
    mail = "feliks@flipdot.org";
  };
  hosts = {
    papawhakaaro = {
      owner = config.krebs.users.feliks;
      nets = {
        retiolum = {
          ip4.addr = "10.243.10.243";
          aliases = [ "papawhakaaro.r" ];
          tinc.pubkey = ''
            -----BEGIN RSA PUBLIC KEY-----
            MIICCgKCAgEA4bd0lVUVlzFmM8TuH77C5VctcK4lkw02LbMVQDJ5U+Ww075nNahw
            oRHqPgJRwfGW0Tgu/1s5czZ2tAFU3lXoOSBYldAspM3KRZ4DKQsFrL9B0oWarGsK
            sUgsuOJprlX4mkfj/eBNINqTqf2kVIH+p43VENQ9ioKmc+qJKm4xfRONRLp871GV
            5jmIvRvQ6JP0RtNd2KpNLaeplzx8M61D9PBOAZkNYAUTpBs4LZBNJj4eFnXBugrz
            GkBjmm3Rk7olz0uOZzbeTc6Slv2tgtN5FrQifdy4XIlsKcBTzMkYHEZstmldJgd9
            pGvfmem6uPcXrF+eDJzqUn0ArH7eOIS4F0+DzugJz4qX+ytvE4ag7r2Vx0Pa9TCY
            hpn0lqwW+ly1clM0SKt59v1nQ4oRW4UIbAZaIgp4UJbb3IGSwbq7NuadvHpNICHi
            4pqQD+1sSEbGLAZ0bFjLIYFg9zzNjLeAxXpn49WHOEyRlq3h+SUQcG2EuVMI28DX
            lILKSoOJsuQupURPubaxkiNEa5neYk9hZ8CWgwSG/VlyRLuNsVDVn2dBma43Mr10
            LHMkX2/a9t7ghokugvV2XMP9Es9A9TGFShM9UtFAlovdad+SQ8FBPNheDwIhjCJe
            l5NIrMrmQIveq7QJ1szxYhqfl1ifU0c+YxeMkg3tvEuQV/tk/oki/aECAwEAAQ==
            -----END RSA PUBLIC KEY-----
          '';
          tinc.pubkey_ed25519 = "5G49yQPjkkoGZxM6CeDy87y6tB/abtelUAk55wJ4GpP";
        };
      };
    };
    iti = {
      owner = config.krebs.users.feliks;
      nets = {
        retiolum = {
          ip4.addr = "10.243.10.244";
          aliases = [ "iti.r" ];
          tinc.pubkey = ''
            -----BEGIN RSA PUBLIC KEY-----
            MIICCgKCAgEA5TXEmw3F3lCekITBPW8QYF1ciKHN8RSi47k1vW+jXb6gdWcVo5KL
            Ithq3T2+jWJJQoOJEDl5Tvo9ilF0oE0AqSNnvfgS/t8xfFVEsNvHodbonXXku5cF
            N7oFooAgQRXAUJpEQLtcfx9kJutSYgGeEvoRGZkWaqY6tzPL45U2WEna+MJ/P1Cd
            57JMOLeJJEjZKtC/XqPOQ81KNcm161RKekHas5ZNK30QEVP9QsjTDoLesYwm1ywt
            4LiHRHSSHd65pKXJvi1haEYw25BxIun7kY4IQHrfEuK3DNs0kyYJj2rKL4C9kHgT
            hYd+fFl1i/X1BjPzo+ZY91ahLVX3UPpOsB8vC9Q7Ctm1Nkc/bCfKRUNbamkS0Bwf
            tngak3heGvuek6Y7qWQUkvMkPLhZwZUXUz+DBXGWXabP5LL8Z/y3V+Qqj0snEsZ3
            9iOF+eeDw2/9hBzRzBPGtwL1DREgd+1J/XlHLcjF4jzkMhweIXw2Yh0Jq7D5Nqf3
            kPF9n/50zbQneSGEiKFeHm1ykag/KV0ebWHUOy1Gydbs7+RxT9GUiZofI6kyjJUI
            g1w1ajkZYIIqhIvhMHudLay5h4kLkdGN9yuRNO/BG5sGk5MywZHyMploIX0ZRVui
            +H3Sx2y268r/Fs6JcaddmzFwFqNmdRTRv/KBp91QGnjcaJDzQPKg/IsCAwEAAQ==
            -----END RSA PUBLIC KEY-----
          '';
          tinc.pubkey_ed25519 = "uG9D7hrWNx+9otDFlZ8Yi31L6xxC7dzGlqXBLkzJCwE";
        };
      };
    };
  };
}
