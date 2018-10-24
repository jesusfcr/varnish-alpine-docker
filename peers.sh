#!/bin/sh

if [[ -z $VARNISH_PEER_URL ]]; then
  echo "peers.sh: No VARNISH_PEER_URL defined, not checking peers."
  exit 0
fi

source functions.sh

wait_for_varnish_start

while true; do

  sleep ${VARNISH_DNS_TTL:-13}
  get_peers

  sha256sum -cs /tmp/peers.sha 2>/dev/null
    if [[ 1 -eq $? ]]; then
      echo "peers.sh: Peers list changed"
      update_peers
      ./reload_varnish.sh
    fi
  done

done
