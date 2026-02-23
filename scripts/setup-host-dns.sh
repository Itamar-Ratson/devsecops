#!/usr/bin/env bash
# setup-host-dns.sh — One-time host DNS prerequisite for KinD cluster
#
# This script configures systemd-resolved to forward all *.domain DNS queries
# to a local dnsmasq instance (started by Terraform on port 5353). This enables
# split-horizon DNS: the host resolves service URLs directly to the local
# gateway instead of going through Cloudflare tunnel.
#
# Run ONCE per machine before the first `terragrunt run --all apply`:
#
#   sudo ./scripts/setup-host-dns.sh [domain]
#
# The file it creates persists across cluster recreations (it is a
# machine-level setting). When the cluster is destroyed and dnsmasq stops,
# queries fall through to public DNS — no cleanup needed.
#
# The script is idempotent — safe to re-run with the same or different domain.

set -euo pipefail

DOMAIN="${1:-itamarratson.com}"
CONF_DIR="/etc/systemd/resolved.conf.d"
CONF_FILE="${CONF_DIR}/kind-gateway.conf"

if [ "$(id -u)" -ne 0 ]; then
  echo "ERROR: this script must be run as root (sudo $0)" >&2
  exit 1
fi

mkdir -p "${CONF_DIR}"

tee "${CONF_FILE}" > /dev/null <<EOF
[Resolve]
DNS=127.0.0.1:5353
Domains=~${DOMAIN}
EOF

echo "Written: ${CONF_FILE} (domain: ${DOMAIN})"

systemctl restart systemd-resolved
echo "Restarted systemd-resolved."
echo
echo "Done. You can now run: cd terraform/live && terragrunt run --all apply --non-interactive"
