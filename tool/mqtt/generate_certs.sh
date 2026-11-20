#!/bin/sh
# Self-signed CA and server certificate (localhost, 127.0.0.1) for the TLS
# listener of the local test broker. Output: docker/mosquitto/certs/
# (git-ignored). Test use only.
#
# Phones/emulators reach the broker via another address; add it with
#   EXTRA_SAN="IP:192.168.1.20" tool/mqtt/generate_certs.sh
# (emulator: IP:10.0.2.2), then restart the broker.
set -eu
cd "$(dirname "$0")/../.."
out=docker/mosquitto/certs
mkdir -p "$out"
cd "$out"

openssl req -x509 -newkey rsa:2048 -nodes -days 825 \
  -keyout ca.key -out ca.crt -subj "/CN=ProtocollExplorer Test CA"

openssl req -newkey rsa:2048 -nodes \
  -keyout server.key -out server.csr -subj "/CN=localhost"

printf 'subjectAltName = DNS:localhost, IP:127.0.0.1%s\nextendedKeyUsage = serverAuth\n' \
  "${EXTRA_SAN:+, $EXTRA_SAN}" > server.ext

openssl x509 -req -in server.csr -CA ca.crt -CAkey ca.key -CAcreateserial \
  -out server.crt -days 825 -extfile server.ext

# The broker runs as user "mosquitto" inside the container.
chmod 0644 ca.crt server.crt server.key
echo "Certificates written to $out"
