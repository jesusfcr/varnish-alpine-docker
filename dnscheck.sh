#!/bin/sh
source functions.sh

wait_for_varnish_start

while true; do

  get_backends
  sleep ${VARNISH_DNS_TTL:-17}
  reload_needed=0

  # Check DNS
  for backend in $(cat /tmp/backend.list); do
    getent ahostsv4 "${backend}" |awk '{print $1}' | head -n 1 > "/tmp/lookup_${backend}.new"

    # Compare old vs new
    cmp -s "/tmp/lookup_${backend}.new" "/tmp/lookup_${backend}.curr"
    if [[ 1 -eq $? ]]; then
      if [[ -s "/tmp/lookup_${backend}.curr" ]]; then
        # DNS has changed!
        echo "dnscheck.sh: DNS changed for ${backend}"
        reload_needed=1
      else
        echo "dnscheck.sh: First check for ${backend} - skipping reload"
      fi
      mv "/tmp/lookup_${backend}.new" "/tmp/lookup_${backend}.curr"
    fi
  done
  if [[ $reload_needed -ne 0 ]]; then
    ./reload_varnish.sh
  fi

done
