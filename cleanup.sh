#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

log "Cleaning up all resources..."

# Delete KinD cluster
if kind get clusters 2>/dev/null | grep -q "k8s-dev"; then
    log "Deleting KinD cluster 'k8s-dev'..."
    kind delete cluster --name k8s-dev
else
    warn "No KinD cluster 'k8s-dev' found"
fi

# Stop and remove Transit Vault container and volumes
if docker ps -a --format '{{.Names}}' | grep -q vault-transit; then
    log "Removing Transit Vault container and volumes..."
    docker compose down -v
else
    warn "No Transit Vault container found"
fi

# Remove ArgoCD SSH deploy key (optional - keeps the key for reuse)
ARGOCD_SSH_KEY_PATH="${HOME}/.ssh/argocd-deploy-key"
if [ -f "${ARGOCD_SSH_KEY_PATH}" ]; then
    read -p "Remove ArgoCD SSH deploy key (${ARGOCD_SSH_KEY_PATH})? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log "Removing ArgoCD SSH deploy key..."
        rm -f "${ARGOCD_SSH_KEY_PATH}" "${ARGOCD_SSH_KEY_PATH}.pub"
        warn "Remember to also remove the deploy key from GitHub repo settings"
    else
        log "Keeping SSH deploy key for reuse"
    fi
fi

# Clean up any leftover docker networks (kind network)
if docker network ls --format '{{.Name}}' | grep -q "^kind$"; then
    log "Removing 'kind' docker network..."
    docker network rm kind 2>/dev/null || warn "Could not remove 'kind' network (may still be in use)"
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Cleanup complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
log "All resources have been removed."
