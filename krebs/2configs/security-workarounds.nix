{ config, lib, pkgs, ... }:
{
  # OpenSSL pre-3.0.7 vulnerabilities
  nixpkgs.overlays = [
    (self: super: {
      exim =
        super.exim.overrideAttrs (old: let
          key = if builtins.hasAttr "preBuild" old then
            "preBuild"
          else
            "configurePhase";
        in {
          buildInputs = old.buildInputs ++ [ self.gnutls ];
          ${key} = /* sh */ ''
            ${old.${key}}
            sed -Ei '
              s:^USE_OPENSSL=.*:# &:
              s:^# (USE_GNUTLS)=.*:\1=yes:
              s:^# (USE_GNUTLS_PC=.*):\1:
            ' Local/Makefile
          '';
        });
    })
  ];
  # OpenSSL pre-3.0.7 vulnerabilities
  services.nginx.package = lib.mkDefault (pkgs.nginxStable.override { openssl = pkgs.libressl; });
}
