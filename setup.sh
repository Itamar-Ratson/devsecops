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

# Delete existing cluster if it exists
if kind get clusters 2>/dev/null | grep -q "k8s-dev"; then
    warn "Deleting existing k8s-dev cluster..."
    kind delete cluster --name k8s-dev
fi

# Create Kind cluster with disabled CNI
log "Creating Kind cluster..."
kind create cluster --config kind-config.yaml

# Install all CRDs upfront
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

# Install Cilium as CNI and Gateway controller
log "Building and installing Cilium..."
helm dependency build ./helm/cilium
helm upgrade --install cilium ./helm/cilium -n kube-system
log "Waiting for nodes to be ready..."
kubectl wait --for=condition=Ready nodes --all --timeout=300s

# Install Tetragon for security observability
log "Building and installing Tetragon..."
helm dependency build ./helm/tetragon
helm upgrade --install tetragon ./helm/tetragon -n kube-system \
  -f ./helm/ports.yaml \
  -f ./helm/tetragon/values.yaml \
  -f ./helm/tetragon/values-tetragon.yaml
log "Waiting for Tetragon rollout..."
kubectl rollout status -n kube-system ds/tetragon -w

# Install Kyverno for policy management
log "Building and installing Kyverno..."
helm dependency build ./helm/kyverno
helm upgrade --install kyverno ./helm/kyverno -n kyverno --create-namespace \
  -f ./helm/ports.yaml \
  -f ./helm/kyverno/values.yaml \
  -f ./helm/kyverno/values-kyverno.yaml
log "Waiting for Kyverno admission controller..."
kubectl wait --for=condition=Ready pod -l app.kubernetes.io/component=admission-controller -n kyverno --timeout=120s

# Install Kyverno policies
log "Building and installing Kyverno policies..."
helm dependency build ./helm/kyverno-policies
helm upgrade --install kyverno-policies ./helm/kyverno-policies -n kyverno \
  -f ./helm/ports.yaml \
  -f ./helm/kyverno-policies/values.yaml

# Install cert-manager
log "Building and installing cert-manager..."
helm dependency build ./helm/cert-manager
helm upgrade --install cert-manager ./helm/cert-manager -n cert-manager --create-namespace \
  -f ./helm/ports.yaml
log "Waiting for cert-manager..."
kubectl wait --for=condition=Available deployment/cert-manager -n cert-manager --timeout=120s

# Install sealed-secrets
log "Building and installing sealed-secrets..."
helm dependency build ./helm/sealed-secrets
helm upgrade --install sealed-secrets ./helm/sealed-secrets -n sealed-secrets --create-namespace \
  -f ./helm/ports.yaml
log "Waiting for sealed-secrets controller..."
kubectl wait --for=condition=Available deployment/sealed-secrets -n sealed-secrets --timeout=120s

# Bootstrap ArgoCD repository credentials
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
    --from-literal=url=git@github.com:Itamar-Ratson \
    --from-file=sshPrivateKey="${ARGOCD_SSH_KEY_PATH}" \
    --dry-run=client -o yaml | \
    kubectl label --local -f - argocd.argoproj.io/secret-type=repo-creds -o yaml | \
    kubeseal --controller-name=sealed-secrets --controller-namespace=sealed-secrets -o yaml | \
    kubectl apply -f -

log "ArgoCD repository credentials sealed and applied"

# Install Gateway and test application
log "Installing Gateway and http-echo..."
helm upgrade --install gateway ./helm/gateway -n gateway --create-namespace
helm upgrade --install http-echo ./helm/http-echo -n http-echo --create-namespace \
  -f ./helm/ports.yaml

# Install network policies
log "Installing network policies..."
helm upgrade --install network-policies ./helm/network-policies -n kube-system \
  -f ./helm/ports.yaml

# Create monitoring namespace before Strimzi (required for network policies)
log "Creating monitoring namespace for Strimzi network policies..."
kubectl create namespace monitoring

# Install Strimzi Kafka Operator
log "Building and installing Strimzi operator..."
helm dependency build ./helm/strimzi-operator
helm upgrade --install strimzi ./helm/strimzi-operator -n strimzi-system --create-namespace \
  -f ./helm/ports.yaml \
  -f ./helm/strimzi-operator/values.yaml \
  -f ./helm/strimzi-operator/values-strimzi.yaml
log "Waiting for Strimzi operator..."
kubectl wait --for=condition=Available deployment/strimzi-cluster-operator -n strimzi-system --timeout=120s

# Install Kafka cluster
log "Installing Kafka cluster..."
helm upgrade --install kafka ./helm/kafka -n kafka --create-namespace \
  -f ./helm/ports.yaml \
  -f ./helm/kafka/values.yaml
log "Waiting for Kafka cluster (this may take a few minutes)..."
kubectl wait --for=condition=Ready kafka/main -n kafka --timeout=300s

# Install monitoring stack
log "Building and installing monitoring stack..."
helm dependency build ./helm/monitoring
helm upgrade --install monitoring ./helm/monitoring -n monitoring \
  -f ./helm/ports.yaml \
  -f ./helm/monitoring/values.yaml \
  -f ./helm/monitoring/values-kube-prometheus.yaml \
  -f ./helm/monitoring/values-loki.yaml \
  -f ./helm/monitoring/values-alloy.yaml \
  -f ./helm/monitoring/values-alloy-consumer.yaml \
  -f ./helm/monitoring/values-tempo.yaml

# Install Kafka UI
log "Building and installing Kafka UI..."
helm dependency build ./helm/kafka-ui
helm upgrade --install kafka-ui ./helm/kafka-ui -n kafka-ui --create-namespace \
  -f ./helm/ports.yaml \
  -f ./helm/kafka-ui/values.yaml \
  -f ./helm/kafka-ui/values-kafka-ui.yaml

# Install ArgoCD
log "Building and installing ArgoCD..."
helm dependency build ./helm/argocd
helm upgrade --install argocd ./helm/argocd -n argocd --create-namespace \
  -f ./helm/ports.yaml \
  -f ./helm/argocd/values.yaml \
  -f ./helm/argocd/values-argocd.yaml

# Get ArgoCD admin password
log "Retrieving ArgoCD admin password..."
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

# Test endpoints
log "Testing endpoints..."
echo ""
echo -e "${GREEN}Testing https://echo.localhost${NC}"
curl -k -s https://echo.localhost && echo ""

echo -e "${GREEN}Testing https://hubble.localhost${NC}"
curl -k -s https://hubble.localhost | head -c 100 && echo "..."

echo -e "${GREEN}Testing https://grafana.localhost${NC}"
curl -k -s https://grafana.localhost | head -c 100 && echo "..."

# Print summary
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Cluster setup complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "ArgoCD admin password: ${YELLOW}${ARGOCD_PASSWORD}${NC}"
echo ""
echo "Access URLs:"
echo "  - https://echo.localhost"
echo "  - https://hubble.localhost"
echo "  - https://grafana.localhost"
echo "  - https://kafka-ui.localhost"
echo "  - https://argocd.localhost"
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
