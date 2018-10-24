#!/bin/sh

wait_for_varnish_start()
{
  until (varnishtop -1 >/dev/null) ; do
    echo "Waiting for varnish to start"
    sleep 1
  done
}

get_backends()
{
  BACKEND_LIST=$(varnishadm vcl.show $(varnishadm vcl.list | grep active | awk '{print $4}') | grep '.host' | cut -d '"' -f 2)
  > /tmp/backend.list
  for backend in ${BACKEND_LIST}; do

    if [[ $(getent ahostsv4 ${backend} | awk '{print $1}' |head -n 1) = $backend ]] 2>/dev/null ; then
      echo "dnscheck.sh: WARNING: Backend appears to be an IP address, no need to watch its dns"
      continue
    fi

    if ! getent hosts ${backend} >/dev/null; then
      echo "dnscheck.sh: ERROR: ${backend} is not a valid address"
      exit 1
    fi

    echo $backend >> /tmp/backend.list

    touch "/tmp/lookup_${backend}.curr"
  done
}

get_peers()
{
  PEERS_LIST=$(getent ahostsv4 "${VARNISH_PEER_URL}" | awk '{print $1}' | sort -u | grep -v $(ifconfig eth0 | grep 'inet addr:' | sed -e 's/^.*addr:\(.*\)  Bcast:.*$/\1/'))
  echo "peers:" > /tmp/peers_list.yaml
  for peer in ${PEERS_LIST}; do
    echo "  - ${peer}" >> /tmp/peers_list.yaml
  done
}

update_peers()
{
  sha256sum /tmp/peers_list.yaml > /tmp/peers.sha
  gomplate --datasource peers=file:///tmp/peers_list.yaml --file "${VARNISH_PEERS_GOMPLATE_FILE}" --out "${VARNISH_PEERS_FILE}"
}
