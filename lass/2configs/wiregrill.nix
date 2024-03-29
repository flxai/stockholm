with import <stockholm/lib>;
{ config, pkgs, ... }: let

  self = config.krebs.build.host.nets.wiregrill;
  isRouter = !isNull self.via;

in mkIf (hasAttr "wiregrill" config.krebs.build.host.nets) {
  #hack for modprobe inside containers
  systemd.services."wireguard-wiregrill".path = mkIf config.boot.isContainer (mkBefore [
    (pkgs.writeDashBin "modprobe" ":")
  ]);

  boot.kernel.sysctl = mkIf isRouter {
    "net.ipv6.conf.all.forwarding" = 1;
  };
  krebs.iptables.tables.filter.INPUT.rules = [
     { predicate = "-p udp --dport ${toString self.wireguard.port}"; target = "ACCEPT"; }
  ];
  krebs.iptables.tables.filter.FORWARD.rules = mkIf isRouter (mkBefore [
    { predicate = "-i wiregrill -o wiregrill"; target = "ACCEPT"; }
    { predicate = "-i wiregrill -o retiolum"; target = "ACCEPT"; }
    { predicate = "-i retiolum -o wiregrill"; target = "ACCEPT"; }
    { predicate = "-i wiregrill -o eth0"; target = "ACCEPT"; }
    { predicate = "-o wiregrill -m conntrack --ctstate RELATED,ESTABLISHED"; target = "ACCEPT"; }
  ]);
  systemd.network.networks.wiregrill = {
    matchConfig.Name = "wiregrill";
    address =
      (optional (!isNull self.ip4) "${self.ip4.addr}/16") ++
      (optional (!isNull self.ip6) "${self.ip6.addr}/48")
    ;
  };

  networking.wireguard.interfaces.wiregrill = {
    ips =
      (optional (!isNull self.ip4) self.ip4.addr) ++
      (optional (!isNull self.ip6) self.ip6.addr);
    listenPort = 51820;
    privateKeyFile = (toString <secrets>) + "/wiregrill.key";
    allowedIPsAsRoutes = true;
    peers = mapAttrsToList
      (_: host: {
        allowedIPs = if isRouter then
          (optional (!isNull host.nets.wiregrill.ip4) host.nets.wiregrill.ip4.addr) ++
          (optional (!isNull host.nets.wiregrill.ip6) host.nets.wiregrill.ip6.addr)
        else
          host.nets.wiregrill.wireguard.subnets
        ;
        endpoint = mkIf (!isNull host.nets.wiregrill.via) (host.nets.wiregrill.via.ip4.addr + ":${toString host.nets.wiregrill.wireguard.port}");
        persistentKeepalive = mkIf (!isNull host.nets.wiregrill.via) 61;
        publicKey = (replaceStrings ["\n"] [""] host.nets.wiregrill.wireguard.pubkey);
      })
      (filterAttrs (_: h: hasAttr "wiregrill" h.nets) config.krebs.hosts);
  };
}
