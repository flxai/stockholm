{ config, lib, pkgs, ... }:
# TODO: remove tv lib :)
with lib;
let

  repos = priv-repos // krebs-repos ;
  rules = concatMap krebs-rules (attrValues krebs-repos) ++ concatMap priv-rules (attrValues priv-repos);

  krebs-repos = mapAttrs make-krebs-repo {
    brain = {
      desc = "braiiiins";
    };
  };

  priv-repos = mapAttrs make-priv-repo {
    autosync = { };
  };

  # TODO move users to separate module
  make-priv-repo = name: { desc ? null, ... }: {
    inherit name desc;
    public = false;
  };

  make-krebs-repo = with git; name: { desc ? null, ... }: {
    inherit name desc;
    public = false;
    hooks = {
      post-receive = pkgs.git-hooks.irc-announce {
        nick = config.networking.hostName;
        channel = "#retiolum";
        # TODO remove the hardcoded hostname
        server = "cd.retiolum";
      };
    };
  };

  set-owners = with git;repo: user:
      singleton {
        inherit user;
        repo = [ repo ];
        perm = push "refs/*" [ non-fast-forward create delete merge ];
      };

  set-ro-access = with git; repo: user:
      singleton {
        inherit user;
        repo = [ repo ];
        perm = fetch;
      };

  # TODO: get the list of all krebsministers
  krebsminister = with config.krebs.users; [ lass tv ];
  all-makefu = with config.krebs.users; [ makefu makefu-omo makefu-tsp ];

  priv-rules = repo: set-owners repo all-makefu;

  krebs-rules = repo:
    set-owners repo all-makefu ++ set-ro-access repo krebsminister;

in {
  imports = [{
    krebs.users.makefu-omo = {
        name = "makefu-omo" ;
        pubkey= with builtins; readFile ../../../krebs/Zpubkeys/makefu_omo.ssh.pub;
    };
    krebs.users.makefu-tsp = {
        name = "makefu-tsp" ;
        pubkey= with builtins; readFile ../../../krebs/Zpubkeys/makefu_tsp.ssh.pub;
    };
  }];
  krebs.git = {
    enable = true;
    cgit = false;
    inherit repos rules;
  };
}
