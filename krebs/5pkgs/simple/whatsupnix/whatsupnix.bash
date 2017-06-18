#!/usr/bin/env bash
#
# Prints build logs for failed derivations in quiet build mode (-Q).
# See https://github.com/NixOS/nix/issues/443
#
# Usage:
#
#    nix-build ... -Q ... | whatsupnix [user@target[:port]]
#
# Exit Codes:
#
#   0     No failed derivations could be found.  This either means there where
#         no build errors, or stdin wasn't nix-build output.
#
#   1     Usage error; arguments couldn't be parsed.
#
#   2     Build error; at least one failed derivation could be found.
#

GAWK=${GAWK:-gawk}
NIX_STORE=${NIX_STORE:-nix-store}

broken=$(mktemp)
trap 'rm -f -- "$broken"' EXIT

exec >&2

$GAWK -v broken="$broken" '
  match($0, /^builder for ‘(\/nix\/store\/[^’]+\.drv)’ failed/, m) {
    print m[1] >> broken
  }
  { print $0 }
'

case $# in
  0)
    print_log() {
      NIX_PAGER= $NIX_STORE -l "$1"
    }
    ;;
  1)
    remote_user=${1%%@*}
    if test "$remote_user" = "$1"; then
      remote_user=root
    else
      set -- "${1#$remote_user@}"
    fi
    remote_port=${1##*:}
    if test "$remote_port" = "$1"; then
      remote_port=22
    else
      set -- "${1%:$remote_port}"
    fi
    remote_host=$1
    print_log() {
      ssh "$remote_user@$remote_host" -p "$remote_port" \
          env NIX_PAGER= nix-store -l "$1"
    }
    ;;
  *)
    echo "usage: whatsupnix [[USER@]HOST[:PORT]]" >&2
    exit 1
esac

while read -r drv; do
  title="** FAILED $drv LOG **"
  frame=${title//?/*}

  echo "$frame"
  echo "$title"
  echo "$frame"
  echo

  print_log "$drv"

  echo
done < "$broken"

if test -s "$broken"; then
  exit 2
else
  exit 0
fi
