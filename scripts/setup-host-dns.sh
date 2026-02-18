#!/usr/bin/env bash
# setup-host-dns.sh — One-time host DNS prerequisite for KinD cluster
#
# This script configures systemd-resolved to forward all *.onprem DNS queries
# to a local dnsmasq instance (started by Terraform on port 5353).  It writes
# a drop-in config file and restarts systemd-resolved.
#
# Run ONCE per machine before the first `terragrunt run --all apply`:
#
#   sudo ./scripts/setup-host-dns.sh
#
# The file it creates persists across cluster recreations (it is a
# machine-level setting).  When the cluster is destroyed and dnsmasq stops,
# *.onprem queries return NXDOMAIN — no cleanup needed.

set -euo pipefail

CONF_DIR="/etc/systemd/resolved.conf.d"
CONF_FILE="${CONF_DIR}/kind-gateway.conf"

if [ "$(id -u)" -ne 0 ]; then
  echo "ERROR: this script must be run as root (sudo $0)" >&2
  exit 1
fi

if [ -f "${CONF_FILE}" ]; then
  echo "Already configured: ${CONF_FILE} exists. Nothing to do."
  exit 0
fi

mkdir -p "${CONF_DIR}"

tee "${CONF_FILE}" > /dev/null <<'EOF'
[Resolve]
DNS=127.0.0.1:5353
Domains=~onprem
EOF

echo "Written: ${CONF_FILE}"

systemctl restart systemd-resolved
echo "Restarted systemd-resolved."
echo
echo "Done. You can now run: cd terraform/live && terragrunt run --all apply --non-interactive"
