#!/bin/bash
# Seal Slack webhook URLs for Alertmanager
#
# Usage: ./seal-slack-webhooks.sh <critical-webhook-url> <warning-webhook-url>
#
# This script uses kubeseal to encrypt the Slack webhook URLs.
# The output can be committed to Git safely.
#
# Prerequisites:
#   - kubeseal CLI installed
#   - sealed-secrets controller running in the cluster
#   - kubectl configured to access the cluster

set -e

CRITICAL_WEBHOOK="${1:?Usage: $0 <critical-webhook-url> <warning-webhook-url>}"
WARNING_WEBHOOK="${2:?Usage: $0 <critical-webhook-url> <warning-webhook-url>}"

echo "Sealing Slack webhook URLs for Alertmanager..."
echo ""

# Create temporary secret and seal it
SEALED_OUTPUT=$(kubectl create secret generic alertmanager-slack-webhooks \
    --namespace monitoring \
    --from-literal=slack-critical-webhook="${CRITICAL_WEBHOOK}" \
    --from-literal=slack-warning-webhook="${WARNING_WEBHOOK}" \
    --dry-run=client -o yaml | \
    kubeseal --controller-name=sealed-secrets --controller-namespace=sealed-secrets -o yaml)

# Extract the encrypted values
CRITICAL_ENCRYPTED=$(echo "${SEALED_OUTPUT}" | grep "slack-critical-webhook:" | awk '{print $2}')
WARNING_ENCRYPTED=$(echo "${SEALED_OUTPUT}" | grep "slack-warning-webhook:" | awk '{print $2}')

echo "Add the following to helm/monitoring/values.yaml:"
echo ""
echo "alertmanagerSlackSecrets:"
echo "  enabled: true"
echo "  criticalWebhookEncrypted: \"${CRITICAL_ENCRYPTED}\""
echo "  warningWebhookEncrypted: \"${WARNING_ENCRYPTED}\""
echo ""
echo "Then deploy with:"
echo "  helm upgrade --install monitoring helm/monitoring/ -n monitoring \\"
echo "    -f helm/ports.yaml \\"
echo "    -f helm/monitoring/values.yaml \\"
echo "    -f helm/monitoring/values-kube-prometheus.yaml \\"
echo "    -f helm/monitoring/values-loki.yaml \\"
echo "    -f helm/monitoring/values-alloy.yaml \\"
echo "    -f helm/monitoring/values-tempo.yaml"
