#!/bin/bash
# One-time setup for external Transit Vault
# This script enables the Transit secrets engine and creates the auto-unseal key.
# Only needs to be run once after starting docker-compose.
#
# Prerequisites:
#   - docker-compose up -d
#   - vault CLI installed
#
set -e

export VAULT_ADDR="http://localhost:8100"
export VAULT_TOKEN="transit-root-token"

echo "Waiting for Transit Vault to be ready..."
until vault status >/dev/null 2>&1; do
    sleep 1
done

echo "Enabling Transit secrets engine..."
vault secrets enable transit 2>/dev/null || echo "Transit already enabled"

echo "Creating auto-unseal key..."
vault write -f transit/keys/autounseal 2>/dev/null || echo "Key already exists"

echo "Transit Vault setup complete!"
echo "The in-cluster Vault will now auto-unseal using this Transit instance."
