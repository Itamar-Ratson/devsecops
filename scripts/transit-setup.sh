#!/bin/bash
# One-time setup for external Transit Vault
# This script enables the Transit secrets engine and creates the auto-unseal key.
# Only needs to be run once after starting docker-compose.
#
# Prerequisites:
#   - cp .env.example .env && set VAULT_TRANSIT_TOKEN
#   - docker compose up -d
#   - vault CLI installed
#
set -e

# Load environment from .env file if present
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$SCRIPT_DIR/../.env" ]]; then
    source "$SCRIPT_DIR/../.env"
fi

if [[ -z "$VAULT_TRANSIT_TOKEN" ]]; then
    echo "Error: VAULT_TRANSIT_TOKEN not set. Copy .env.example to .env and set the token."
    exit 1
fi

export VAULT_ADDR="http://localhost:8100"
export VAULT_TOKEN="$VAULT_TRANSIT_TOKEN"

echo "Waiting for Transit Vault to be ready..."
until vault status >/dev/null 2>&1; do
    sleep 1
done

echo "Enabling Transit secrets engine..."
vault secrets enable transit 2>/dev/null || echo "Transit already enabled"

echo "Creating auto-unseal key..."
vault write -f transit/keys/autounseal 2>/dev/null || echo "Key already exists"

echo "Enabling KV v2 secrets engine..."
vault secrets enable -path=secret kv-v2 2>/dev/null || echo "KV engine already enabled"

echo "Transit Vault setup complete!"
echo "The in-cluster Vault will now auto-unseal using this Transit instance."
echo "KV v2 engine available at 'secret/' for static secrets storage."
