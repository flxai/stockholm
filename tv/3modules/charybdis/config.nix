{ config, ... }: with import ./lib; let
  cfg = config.tv.charybdis;
in toFile "charybdis.conf" ''
  /* doc/example.conf - brief example configuration file
   *
   * Copyright (C) 2000-2002 Hybrid Development Team
   * Copyright (C) 2002-2005 ircd-ratbox development team
   * Copyright (C) 2005-2006 charybdis development team
   *
   * $Id: example.conf 3582 2007-11-17 21:55:48Z jilles $
   *
   * See reference.conf for more information.
   */

  /* Extensions */
  #loadmodule "extensions/chm_operonly_compat.so";
  #loadmodule "extensions/chm_quietunreg_compat.so";
  #loadmodule "extensions/chm_sslonly_compat.so";
  #loadmodule "extensions/createauthonly.so";
  #loadmodule "extensions/extb_account.so";
  #loadmodule "extensions/extb_canjoin.so";
  #loadmodule "extensions/extb_channel.so";
  #loadmodule "extensions/extb_extgecos.so";
  #loadmodule "extensions/extb_oper.so";
  #loadmodule "extensions/extb_realname.so";
  #loadmodule "extensions/extb_server.so";
  #loadmodule "extensions/extb_ssl.so";
  #loadmodule "extensions/hurt.so";
  #loadmodule "extensions/m_findforwards.so";
  #loadmodule "extensions/m_identify.so";
  #loadmodule "extensions/no_oper_invis.so";
  #loadmodule "extensions/sno_farconnect.so";
  #loadmodule "extensions/sno_globalkline.so";
  #loadmodule "extensions/sno_globaloper.so";
  #loadmodule "extensions/sno_whois.so";
  loadmodule "extensions/override.so";

  /*
   * IP cloaking extensions: use ip_cloaking_4.0
   * if you're linking 3.2 and later, otherwise use
   * ip_cloaking.so, for compatibility with older 3.x
   * releases.
   */

  #loadmodule "extensions/ip_cloaking_4.0.so";
  #loadmodule "extensions/ip_cloaking.so";

  serverinfo {
    name = ${toJSON (head config.krebs.build.host.nets.retiolum.aliases)};
    sid = "4z3";
    description = "miep!";
    network_name = "irc.r";
    #network_desc = "Retiolum IRC Network";
    hub = yes;

    /* On multi-homed hosts you may need the following. These define
     * the addresses we connect from to other servers. */
    /* for IPv4 */
    vhost = ${toJSON config.krebs.build.host.nets.retiolum.ip4.addr};
    /* for IPv6 */
    vhost6 = ${toJSON config.krebs.build.host.nets.retiolum.ip6.addr};

    /* ssl_private_key: our ssl private key */
    ssl_private_key = "/tmp/credentials/ssl_private_key";

    /* ssl_cert: certificate for our ssl server */
    ssl_cert = ${toJSON cfg.ssl_cert};

    /* ssl_dh_params: DH parameters, generate with openssl dhparam -out dh.pem 1024 */
    ssl_dh_params = "/tmp/credentials/ssl_dh_params";

    /* ssld_count: number of ssld processes you want to start, if you
     * have a really busy server, using N-1 where N is the number of
     * cpu/cpu cores you have might be useful. A number greater than one
     * can also be useful in case of bugs in ssld and because ssld needs
     * two file descriptors per SSL connection.
     */
    ssld_count = 1;

    /* default max clients: the default maximum number of clients
     * allowed to connect.  This can be changed once ircd has started by
     * issuing:
     *   /quote set maxclients <limit>
     */
    default_max_clients = 1024;

    /* nicklen: enforced nickname length (for this server only; must not
     * be longer than the maximum length set while building).
     */
    nicklen = 30;
  };

  admin {
    name = "tv";
    description = "peer";
  };

  log {
    fname_userlog = "/dev/stderr";
    fname_fuserlog = "/dev/stderr";
    fname_operlog = "/dev/stderr";
    fname_foperlog = "/dev/stderr";
    fname_serverlog = "/dev/stderr";
    fname_klinelog = "/dev/stderr";
    fname_killlog = "/dev/stderr";
    fname_operspylog = "/dev/stderr";
    fname_ioerrorlog = "/dev/stderr";
  };

  /* class {} blocks MUST be specified before anything that uses them.  That
   * means they must be defined before auth {} and before connect {}.
   */

  class "krebs" {
    ping_time = 2 minutes;
    number_per_ident = 10;
    number_per_ip = 2048;
    number_per_ip_global = 4096;
    cidr_ipv4_bitlen = 24;
    cidr_ipv6_bitlen = 64;
    number_per_cidr = 65536;
    max_number = 3000;
    sendq = 1 megabyte;
  };

  class "users" {
    ping_time = 2 minutes;
    number_per_ident = 10;
    number_per_ip = 1024;
    number_per_ip_global = 4096;
    cidr_ipv4_bitlen = 24;
    cidr_ipv6_bitlen = 64;
    number_per_cidr = 65536;
    max_number = 3000;
    sendq = 400 kbytes;
  };

  class "opers" {
    ping_time = 5 minutes;
    number_per_ip = 10;
    max_number = 1000;
    sendq = 1 megabyte;
  };

  class "server" {
    ping_time = 5 minutes;
    connectfreq = 5 minutes;
    max_number = 1;
    sendq = 4 megabytes;
  };

  listen {
    /* defer_accept: wait for clients to send IRC handshake data before
     * accepting them.  if you intend to use software which depends on the
     * server replying first, such as BOPM, you should disable this feature.
     * otherwise, you probably want to leave it on.
     */
    defer_accept = yes;

    /* If you want to listen on a specific IP only, specify host.
     * host definitions apply only to the following port line.
     */
    #host = ${toJSON config.krebs.build.host.nets.retiolum.ip4.addr};
    port = ${toString cfg.port};
    sslport = ${toString cfg.sslport};
  };

  /* auth {}: allow users to connect to the ircd (OLD I:)
   * auth {} blocks MUST be specified in order of precedence.  The first one
   * that matches a user will be used.  So place spoofs first, then specials,
   * then general access, then restricted.
   */
  auth {
    /* user: the user@host allowed to connect.  Multiple IPv4/IPv6 user
     * lines are permitted per auth block.  This is matched against the
     * hostname and IP address (using :: shortening for IPv6 and
     * prepending a 0 if it starts with a colon) and can also use CIDR
     * masks.
     */
    user = "*@10.243.0.0/16";
    user = "*@42::/16";

    /* password: an optional password that is required to use this block.
     * By default this is not encrypted, specify the flag "encrypted" in
     * flags = ...; below if it is.
     */
    #password = "letmein";

    /* spoof: fake the users user@host to be be this.  You may either
     * specify a host or a user@host to spoof to.  This is free-form,
     * just do everyone a favour and dont abuse it. (OLD I: = flag)
     */
    #spoof = "I.still.hate.packets";

    /* Possible flags in auth:
     *
     * encrypted                  | password is encrypted with mkpasswd
     * spoof_notice               | give a notice when spoofing hosts
     * exceed_limit (old > flag)  | allow user to exceed class user limits
     * kline_exempt (old ^ flag)  | exempt this user from k/g/xlines&dnsbls
     * dnsbl_exempt		      | exempt this user from dnsbls
     * spambot_exempt	      | exempt this user from spambot checks
     * shide_exempt		      | exempt this user from serverhiding
     * jupe_exempt                | exempt this user from generating
     *                              warnings joining juped channels
     * resv_exempt		      | exempt this user from resvs
     * flood_exempt               | exempt this user from flood limits
     *                                     USE WITH CAUTION.
     * no_tilde     (old - flag)  | don't prefix ~ to username if no ident
     * need_ident   (old + flag)  | require ident for user in this class
     * need_ssl                   | require SSL/TLS for user in this class
     * need_sasl                  | require SASL id for user in this class
     */
    flags = kline_exempt, exceed_limit, flood_exempt;

    /* class: the class the user is placed in */
    class = "krebs";
  };

  auth {
    user = "*@*";
    class = "users";
  };

  /* privset {} blocks MUST be specified before anything that uses them.  That
   * means they must be defined before operator {}.
   */
  privset "local_op" {
    privs = oper:local_kill, oper:operwall;
  };

  privset "server_bot" {
    extends = "local_op";
    privs = oper:kline, oper:remoteban, snomask:nick_changes;
  };

  privset "global_op" {
    extends = "local_op";
    privs = oper:global_kill, oper:routing, oper:kline, oper:unkline, oper:xline,
      oper:resv, oper:mass_notice, oper:remoteban;
  };

  privset "admin" {
    extends = "global_op";
    privs = oper:admin, oper:die, oper:rehash, oper:spy, oper:override;
  };

  privset "aids" {
    privs = oper:override, oper:rehash;
  };

  operator "aids" {
    user = "*@10.243.*";
    privset = "aids";
    flags = ~encrypted;
    password = "balls";
  };

  operator "god" {
    /* name: the name of the oper must go above */

    /* user: the user@host required for this operator.  CIDR *is*
     * supported now. auth{} spoofs work here, other spoofs do not.
     * multiple user="" lines are supported.
     */
    user = "*god@127.0.0.1";

    /* password: the password required to oper.  Unless ~encrypted is
     * contained in flags = ...; this will need to be encrypted using
     * mkpasswd, MD5 is supported
     */
    password = "5";

    /* rsa key: the public key for this oper when using Challenge.
     * A password should not be defined when this is used, see
     * doc/challenge.txt for more information.
     */
    #rsa_public_key_file = "/usr/local/ircd/etc/oper.pub";

    /* umodes: the specific umodes this oper gets when they oper.
     * If this is specified an oper will not be given oper_umodes
     * These are described above oper_only_umodes in general {};
     */
    #umodes = locops, servnotice, operwall, wallop;

    /* fingerprint: if specified, the oper's client certificate
     * fingerprint will be checked against the specified fingerprint
     * below.
     */
    #fingerprint = "c77106576abf7f9f90cca0f63874a60f2e40a64b";

    /* snomask: specific server notice mask on oper up.
     * If this is specified an oper will not be given oper_snomask.
     */
    snomask = "+Zbfkrsuy";

    /* flags: misc options for the operator.  You may prefix an option
     * with ~ to disable it, e.g. ~encrypted.
     *
     * Default flags are encrypted.
     *
     * Available options:
     *
     * encrypted:    the password above is encrypted [DEFAULT]
     * need_ssl:     must be using SSL/TLS to oper up
     */
    flags = encrypted;

    /* privset: privileges set to grant */
    privset = "admin";
  };

  service {
    name = "services.int";
  };

  cluster {
    name = "*";
    flags = kline, tkline, unkline, xline, txline, unxline, resv, tresv, unresv;
  };

  shared {
    oper = "*@*", "*";
    flags = all, rehash;
  };

  /* exempt {}: IPs that are exempt from Dlines and rejectcache. (OLD d:) */
  exempt {
    ip = "127.0.0.1";
  };

  channel {
    use_invex = yes;
    use_except = yes;
    use_forward = yes;
    use_knock = yes;
    knock_delay = 5 minutes;
    knock_delay_channel = 1 minute;
    max_chans_per_user = 15;
    max_bans = 100;
    max_bans_large = 500;
    default_split_user_count = 0;
    default_split_server_count = 0;
    no_create_on_split = no;
    no_join_on_split = no;
    burst_topicwho = yes;
    kick_on_split_riding = no;
    only_ascii_channels = no;
    resv_forcepart = yes;
    channel_target_change = yes;
    disable_local_channels = no;
  };

  serverhide {
    flatten_links = yes;
    links_delay = 5 minutes;
    hidden = no;
    disable_hidden = no;
  };

  /* These are the blacklist settings.
   * You can have multiple combinations of host and rejection reasons.
   * They are used in pairs of one host/rejection reason.
   *
   * These settings should be adequate for most networks, and are (presently)
   * required for use on StaticBox.
   *
   * Word to the wise: Do not use blacklists like SPEWS for blocking IRC
   * connections.
   *
   * As of charybdis 2.2, you can do some keyword substitution on the rejection
   * reason. The available keyword substitutions are:
   *
   *   ''${ip}           - the user's IP
   *   ''${host}         - the user's canonical hostname
   *   ''${dnsbl-host}   - the dnsbl hostname the lookup was done against
   *   ''${nick}         - the user's nickname
   *   ''${network-name} - the name of the network
   *
   * As of charybdis 3.4, a type parameter is supported, which specifies the
   * address families the blacklist supports. IPv4 and IPv6 are supported.
   * IPv4 is currently the default as few blacklists support IPv6 operation
   * as of this writing.
   *
   * Note: AHBL (the providers of the below *.ahbl.org BLs) request that they be
   * contacted, via email, at admins@2mbit.com before using these BLs.
   * See <http://www.ahbl.org/services.php> for more information.
   */
  blacklist {
    host = "rbl.efnetrbl.org";
    type = ipv4;
    reject_reason = "''${nick}, your IP (''${ip}) is listed in EFnet's RBL. For assistance, see http://efnetrbl.org/?i=''${ip}";

  #	host = "ircbl.ahbl.org";
  #	type = ipv4;
  #	reject_reason = "''${nick}, your IP (''${ip}) is listed in ''${dnsbl-host} for having an open proxy. In order to protect ''${network-name} from abuse, we are not allowing connections with open proxies to connect.";
  #
  #	host = "tor.ahbl.org";
  #	type = ipv4;
  #	reject_reason = "''${nick}, your IP (''${ip}) is listed as a TOR exit node. In order to protect ''${network-name} from tor-based abuse, we are not allowing TOR exit nodes to connect to our network.";
  #
    /* Example of a blacklist that supports both IPv4 and IPv6 */
  #	host = "foobl.blacklist.invalid";
  #	type = ipv4, ipv6;
  #	reject_reason = "''${nick}, your IP (''${ip}) is listed in ''${dnsbl-host} for some reason. In order to protect ''${network-name} from abuse, we are not allowing connections listed in ''${dnsbl-host} to connect";
  };

  alias "NickServ" {
    target = "NickServ";
  };

  alias "ChanServ" {
    target = "ChanServ";
  };

  alias "OperServ" {
    target = "OperServ";
  };

  alias "MemoServ" {
    target = "MemoServ";
  };

  alias "NS" {
    target = "NickServ";
  };

  alias "CS" {
    target = "ChanServ";
  };

  alias "OS" {
    target = "OperServ";
  };

  alias "MS" {
    target = "MemoServ";
  };

  general {
    hide_error_messages = opers;
    hide_spoof_ips = yes;

    /*
     * default_umodes: umodes to enable on connect.
     * If you have enabled the new ip_cloaking_4.0 module, and you want
     * to make use of it, add +x to this option, i.e.:
     *      default_umodes = "+ix";
     *
     * If you have enabled the old ip_cloaking module, and you want
     * to make use of it, add +h to this option, i.e.:
     *	default_umodes = "+ih";
     */
    default_umodes = "+i";

    default_operstring = "is an IRC Operator";
    default_adminstring = "is a Server Administrator";
    servicestring = "is a Network Service";
    disable_fake_channels = no;
    tkline_expire_notices = no;
    default_floodcount = 1000;
    failed_oper_notice = yes;
    dots_in_ident=2;
    min_nonwildcard = 4;
    min_nonwildcard_simple = 3;
    max_accept = 100;
    max_monitor = 100;
    anti_nick_flood = yes;
    max_nick_time = 20 seconds;
    max_nick_changes = 5;
    anti_spam_exit_message_time = 5 minutes;
    ts_warn_delta = 30 seconds;
    ts_max_delta = 5 minutes;
    client_exit = yes;
    collision_fnc = yes;
    resv_fnc = yes;
    global_snotices = yes;
    dline_with_reason = yes;
    kline_delay = 0 seconds;
    kline_with_reason = yes;
    kline_reason = "K-Lined";
    identify_service = "NickServ@services.int";
    identify_command = "IDENTIFY";
    non_redundant_klines = yes;
    warn_no_nline = yes;
    use_propagated_bans = yes;
    stats_e_disabled = no;
    stats_c_oper_only=no;
    stats_h_oper_only=no;
    client_flood_max_lines = 16000;
    client_flood_burst_rate = 32000;
    client_flood_burst_max = 32000;
    client_flood_message_num = 32000;
    client_flood_message_time = 32000;
    use_whois_actually = no;
    oper_only_umodes = operwall, locops, servnotice;
    oper_umodes = locops, servnotice, operwall, wallop;
    oper_snomask = "+s";
    burst_away = yes;
    nick_delay = 0 seconds; # 15 minutes if you want to enable this
    reject_ban_time = 1 minute;
    reject_after_count = 3;
    reject_duration = 5 minutes;
    throttle_duration = 1;
    throttle_count = 1000;
    max_ratelimit_tokens = 30;
    away_interval = 30;
    disable_auth = yes;
  };

  modules {
    path = "modules";
    path = "modules/autoload";
  };

  exempt {
    ip = "10.243.0.0/16";
  };
''
