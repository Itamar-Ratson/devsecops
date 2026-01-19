#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# Check prerequisites
command -v docker >/dev/null 2>&1 || error "docker is required but not installed"
command -v kubectl >/dev/null 2>&1 || error "kubectl is required but not installed"
command -v helm >/dev/null 2>&1 || error "helm is required but not installed"
command -v kind >/dev/null 2>&1 || error "kind is required but not installed"
command -v kubeseal >/dev/null 2>&1 || error "kubeseal is required but not installed"
command -v gh >/dev/null 2>&1 || error "gh (GitHub CLI) is required but not installed"

log "Starting Kubernetes cluster setup..."

# Load environment variables from .env file
if [[ -f ".env" ]]; then
    log "Loading environment from .env file..."
    source .env
else
    error ".env file not found. Copy .env.example to .env and configure it"
fi

# Validate required environment variables
MISSING_VARS=""
[[ -z "$GIT_REPO_URL" ]] && MISSING_VARS="$MISSING_VARS GIT_REPO_URL"
[[ -z "$VAULT_TRANSIT_TOKEN" ]] && MISSING_VARS="$MISSING_VARS VAULT_TRANSIT_TOKEN"
[[ -z "$GRAFANA_ADMIN_USER" ]] && MISSING_VARS="$MISSING_VARS GRAFANA_ADMIN_USER"
[[ -z "$GRAFANA_ADMIN_PASSWORD" ]] && MISSING_VARS="$MISSING_VARS GRAFANA_ADMIN_PASSWORD"
[[ -z "$ARGOCD_ADMIN_PASSWORD_HASH" ]] && MISSING_VARS="$MISSING_VARS ARGOCD_ADMIN_PASSWORD_HASH"
[[ -z "$ARGOCD_SERVER_SECRET_KEY" ]] && MISSING_VARS="$MISSING_VARS ARGOCD_SERVER_SECRET_KEY"
[[ -z "$KEYCLOAK_ADMIN_USER" ]] && MISSING_VARS="$MISSING_VARS KEYCLOAK_ADMIN_USER"
[[ -z "$KEYCLOAK_ADMIN_PASSWORD" ]] && MISSING_VARS="$MISSING_VARS KEYCLOAK_ADMIN_PASSWORD"
[[ -z "$ARGOCD_OIDC_CLIENT_SECRET" ]] && MISSING_VARS="$MISSING_VARS ARGOCD_OIDC_CLIENT_SECRET"
[[ -z "$GRAFANA_OIDC_CLIENT_SECRET" ]] && MISSING_VARS="$MISSING_VARS GRAFANA_OIDC_CLIENT_SECRET"
[[ -z "$VAULT_OIDC_CLIENT_SECRET" ]] && MISSING_VARS="$MISSING_VARS VAULT_OIDC_CLIENT_SECRET"

if [[ -n "$MISSING_VARS" ]]; then
    error "Missing required environment variables in .env:$MISSING_VARS"
fi

log "Git repo: ${GIT_REPO_URL}"

# ============================================================================
# CLEAN SLATE: Delete everything for a fresh start
# ============================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"${SCRIPT_DIR}/cleanup.sh" --skip-ssh-prompt

# Start fresh Transit Vault
log "Starting Transit Vault..."
docker compose up -d

# Wait for Transit Vault to be ready
log "Waiting for Transit Vault to be ready..."
until docker exec vault-transit sh -c 'VAULT_ADDR=http://127.0.0.1:8200 vault status' >/dev/null 2>&1; do
    sleep 1
done

# Initialize Transit secrets engine (need VAULT_ADDR and VAULT_TOKEN for authentication)
log "Initializing Transit secrets engine..."
docker exec -e VAULT_ADDR=http://127.0.0.1:8200 -e VAULT_TOKEN="$VAULT_TRANSIT_TOKEN" vault-transit vault secrets enable transit 2>/dev/null || true
docker exec -e VAULT_ADDR=http://127.0.0.1:8200 -e VAULT_TOKEN="$VAULT_TRANSIT_TOKEN" vault-transit vault write -f transit/keys/autounseal 2>/dev/null || true

# ============================================================================
# Create KinD cluster and connect Transit Vault
# ============================================================================

# Create Kind cluster with disabled CNI
log "Creating Kind cluster..."
kind create cluster --config kind-config.yaml

# Connect Transit Vault to KinD network with static IP
# KinD uses different subnets depending on existing Docker networks, detect dynamically
KIND_SUBNET=$(docker network inspect kind --format '{{range .IPAM.Config}}{{.Subnet}} {{end}}' | tr ' ' '\n' | grep "^172\." | head -1)
TRANSIT_VAULT_IP="$(echo "$KIND_SUBNET" | cut -d'.' -f1-3).100"
log "Connecting Transit Vault to KinD network with static IP ${TRANSIT_VAULT_IP}..."
docker network connect --ip "$TRANSIT_VAULT_IP" kind vault-transit 2>/dev/null || {
    # If already connected, disconnect and reconnect with static IP
    docker network disconnect kind vault-transit 2>/dev/null || true
    docker network connect --ip "$TRANSIT_VAULT_IP" kind vault-transit
}
log "Transit Vault IP on KinD network: $TRANSIT_VAULT_IP"

# ============================================================================
# Install CRDs (required before operators)
# ============================================================================
log "Installing Gateway API CRDs (experimental for Cilium)..."
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.2.1/experimental-install.yaml

log "Installing Prometheus Operator CRDs..."
kubectl apply -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.87.1/example/prometheus-operator-crd/monitoring.coreos.com_servicemonitors.yaml
kubectl apply --server-side -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.87.1/example/prometheus-operator-crd/monitoring.coreos.com_prometheuses.yaml
kubectl apply --server-side -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.87.1/example/prometheus-operator-crd/monitoring.coreos.com_alertmanagers.yaml
kubectl apply --server-side -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.87.1/example/prometheus-operator-crd/monitoring.coreos.com_podmonitors.yaml
kubectl apply --server-side -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.87.1/example/prometheus-operator-crd/monitoring.coreos.com_prometheusrules.yaml

log "Installing cert-manager CRDs..."
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.19.2/cert-manager.crds.yaml

# Add required Helm repositories
log "Adding Helm repositories..."
helm repo add hashicorp https://helm.releases.hashicorp.com 2>/dev/null || true
helm repo update

# ============================================================================
# Install Cilium CNI (required for cluster networking)
# ============================================================================
log "Building and installing Cilium..."
helm dependency build ./helm/cilium
helm upgrade --install cilium ./helm/cilium -n kube-system
log "Waiting for nodes to be ready..."
kubectl wait --for=condition=Ready nodes --all --timeout=300s

# ============================================================================
# Install Sealed-Secrets (required for ArgoCD repo credentials)
# ============================================================================
log "Building and installing sealed-secrets..."
helm dependency build ./helm/sealed-secrets
helm upgrade --install sealed-secrets ./helm/sealed-secrets -n sealed-secrets --create-namespace \
  -f ./helm/ports.yaml
log "Waiting for sealed-secrets controller..."
kubectl wait --for=condition=Available deployment/sealed-secrets -n sealed-secrets --timeout=120s

# ============================================================================
# Bootstrap ArgoCD repository credentials
# ============================================================================
ARGOCD_SSH_KEY_PATH="${HOME}/.ssh/argocd-deploy-key"
ARGOCD_SSH_KEY_GENERATED=false

if [ ! -f "${ARGOCD_SSH_KEY_PATH}" ]; then
    log "Generating SSH deploy key for ArgoCD..."
    ssh-keygen -t ed25519 -C "argocd-deploy-key" -f "${ARGOCD_SSH_KEY_PATH}" -N ""
    ARGOCD_SSH_KEY_GENERATED=true
else
    log "Using existing SSH deploy key: ${ARGOCD_SSH_KEY_PATH}"
fi

log "Creating and sealing ArgoCD repository credentials..."
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

# Create the secret and seal it
kubectl create secret generic argocd-repo-creds \
    --namespace argocd \
    --from-literal=type=git \
    --from-literal=url="${GIT_REPO_URL}" \
    --from-file=sshPrivateKey="${ARGOCD_SSH_KEY_PATH}" \
    --dry-run=client -o yaml | \
    kubectl label --local -f - argocd.argoproj.io/secret-type=repo-creds -o yaml | \
    kubeseal --controller-name=sealed-secrets --controller-namespace=sealed-secrets -o yaml | \
    kubectl apply -f -

log "ArgoCD repository credentials sealed and applied"

# ============================================================================
# Create Vault prerequisites (ArgoCD will deploy Vault via sync waves)
# ============================================================================
log "Creating Vault namespace and transit token secret..."
kubectl create namespace vault --dry-run=client -o yaml | kubectl apply -f -

# Create the transit token secret that Vault needs for auto-unseal
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: vault-transit-token
  namespace: vault
type: Opaque
stringData:
  VAULT_TOKEN: "${VAULT_TRANSIT_TOKEN}"
EOF

# Create Secret with bootstrap secrets for Vault
# These will be used by the bootstrap job to seed Vault with initial secrets
# Note: Use temp files to avoid shell expansion of $ in passwords/hashes
SECRETS_DIR=$(mktemp -d)
grep GRAFANA_ADMIN_USER .env | cut -d'=' -f2- > "$SECRETS_DIR/grafana-user"
grep GRAFANA_ADMIN_PASSWORD .env | cut -d'=' -f2- > "$SECRETS_DIR/grafana-password"
grep ARGOCD_ADMIN_PASSWORD_HASH .env | cut -d'=' -f2- > "$SECRETS_DIR/argocd-password-hash"
grep ARGOCD_SERVER_SECRET_KEY .env | cut -d'=' -f2- > "$SECRETS_DIR/argocd-server-secret-key"
# Alertmanager secrets (optional - defaults to empty)
grep PAGERDUTY_ROUTING_KEY .env | cut -d'=' -f2- > "$SECRETS_DIR/pagerduty-routing-key" 2>/dev/null || echo -n "" > "$SECRETS_DIR/pagerduty-routing-key"
grep SLACK_CRITICAL_WEBHOOK .env | cut -d'=' -f2- > "$SECRETS_DIR/slack-critical-webhook" 2>/dev/null || echo -n "" > "$SECRETS_DIR/slack-critical-webhook"
grep SLACK_WARNING_WEBHOOK .env | cut -d'=' -f2- > "$SECRETS_DIR/slack-warning-webhook" 2>/dev/null || echo -n "" > "$SECRETS_DIR/slack-warning-webhook"
# Keycloak secrets
grep KEYCLOAK_ADMIN_USER .env | cut -d'=' -f2- > "$SECRETS_DIR/keycloak-admin-user"
grep KEYCLOAK_ADMIN_PASSWORD .env | cut -d'=' -f2- > "$SECRETS_DIR/keycloak-admin-password"
grep ARGOCD_OIDC_CLIENT_SECRET .env | cut -d'=' -f2- > "$SECRETS_DIR/argocd-oidc-client-secret"
grep GRAFANA_OIDC_CLIENT_SECRET .env | cut -d'=' -f2- > "$SECRETS_DIR/grafana-oidc-client-secret"
grep VAULT_OIDC_CLIENT_SECRET .env | cut -d'=' -f2- > "$SECRETS_DIR/vault-oidc-client-secret"
kubectl create secret generic vault-bootstrap-secrets \
    --namespace vault \
    --from-file="$SECRETS_DIR/grafana-user" \
    --from-file="$SECRETS_DIR/grafana-password" \
    --from-file="$SECRETS_DIR/argocd-password-hash" \
    --from-file="$SECRETS_DIR/argocd-server-secret-key" \
    --from-file="$SECRETS_DIR/pagerduty-routing-key" \
    --from-file="$SECRETS_DIR/slack-critical-webhook" \
    --from-file="$SECRETS_DIR/slack-warning-webhook" \
    --from-file="$SECRETS_DIR/keycloak-admin-user" \
    --from-file="$SECRETS_DIR/keycloak-admin-password" \
    --from-file="$SECRETS_DIR/argocd-oidc-client-secret" \
    --from-file="$SECRETS_DIR/grafana-oidc-client-secret" \
    --from-file="$SECRETS_DIR/vault-oidc-client-secret" \
    --dry-run=client -o yaml | kubectl apply -f -
rm -rf "$SECRETS_DIR"

log "Vault prerequisites created - ArgoCD will deploy Vault in Wave 2"

# Create ArgoCD OIDC secret for Dex (needed before VSO is deployed)
# This will be synced by VaultStaticSecret once VSO is available
log "Creating ArgoCD OIDC secret for Dex..."
ARGOCD_OIDC_SECRET=$(grep ARGOCD_OIDC_CLIENT_SECRET .env | cut -d'=' -f2-)
kubectl create secret generic argocd-oidc-secret \
    --namespace argocd \
    --from-literal=argocd-client-secret="${ARGOCD_OIDC_SECRET}" \
    --from-literal=dex.keycloak.clientSecret="${ARGOCD_OIDC_SECRET}" \
    --dry-run=client -o yaml | kubectl apply -f -

# ============================================================================
# Install ArgoCD (GitOps controller)
# ============================================================================
log "Building and installing ArgoCD..."
helm dependency build ./helm/argocd

# Initial install: disable gitops and vaultSecrets (CRDs don't exist yet)
# VaultStaticSecrets will be created when ArgoCD syncs itself after VSO is deployed
helm upgrade --install argocd ./helm/argocd -n argocd --create-namespace \
  -f ./helm/ports.yaml \
  -f ./helm/argocd/values.yaml \
  -f ./helm/argocd/values-argocd.yaml \
  --set gitops.repoURL="${GIT_REPO_URL}" \
  --set gitops.enabled=false \
  --set vaultSecrets.enabled=false
log "Waiting for ArgoCD server..."
kubectl wait --for=condition=Available deployment/argocd-server -n argocd --timeout=180s

# Enable GitOps - ArgoCD will deploy all infrastructure via sync waves
# VaultStaticSecrets are still disabled - they'll be created when ArgoCD syncs itself from git after VSO is deployed
log "Enabling GitOps (ArgoCD will deploy all infrastructure)..."
helm upgrade argocd ./helm/argocd -n argocd \
  -f ./helm/ports.yaml \
  -f ./helm/argocd/values.yaml \
  -f ./helm/argocd/values-argocd.yaml \
  --set gitops.repoURL="${GIT_REPO_URL}" \
  --set vaultSecrets.enabled=false

# Get ArgoCD admin password
log "Retrieving ArgoCD admin password..."
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" 2>/dev/null | base64 -d || echo "See argocd-secret")

# ============================================================================
# Summary
# ============================================================================
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Bootstrap complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "ArgoCD admin password: ${YELLOW}${ARGOCD_PASSWORD}${NC}"
echo ""
echo "ArgoCD is now deploying all infrastructure via GitOps sync waves:"
echo "  Wave 0: ArgoCD (self-managed)"
echo "  Wave 1: Tetragon, Kyverno, Trivy, cert-manager, Sealed-secrets, Strimzi, Network-policies"
echo "  Wave 2: Kyverno-policies, Vault, Kafka"
echo "  Wave 3: Vault-secrets-operator, Gateway, Kafka-UI"
echo "  Wave 4: http-echo, juice-shop, Keycloak"
echo "  Wave 5: Monitoring"
echo ""
echo "Monitor progress:"
echo "  - ArgoCD UI: https://argocd.localhost (admin / ${ARGOCD_PASSWORD})"
echo "  - kubectl get applications -n argocd"
echo ""

# Add deploy key to GitHub using gh CLI
if [ "${ARGOCD_SSH_KEY_GENERATED}" = true ]; then
    GITHUB_REPO=$(gh repo view --json nameWithOwner -q '.nameWithOwner')
    log "Adding SSH deploy key to GitHub repository (${GITHUB_REPO})..."
    if gh repo deploy-key add "${ARGOCD_SSH_KEY_PATH}.pub" \
        --repo "${GITHUB_REPO}" \
        --title "argocd-deploy-key" 2>/dev/null; then
        log "Deploy key added successfully"
    else
        warn "Could not add deploy key (may already exist or insufficient permissions)"
        warn "If needed, add manually at: https://github.com/${GITHUB_REPO}/settings/keys"
    fi
else
    log "Using existing SSH deploy key: ${ARGOCD_SSH_KEY_PATH}"
fi
