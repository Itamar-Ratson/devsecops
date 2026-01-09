# Kubernetes Local Dev Setup

KinD + Cilium (CNI + Gateway) + Gateway API + cert-manager + Sealed Secrets + Hubble + Tetragon + Network Policies + Monitoring (Prometheus + Grafana + Loki + Alloy + Tempo)

## Prerequisites

Docker, kubectl, Helm, KinD, kubeseal

# Increase inotify limits (required for Hubble mTLS and monitoring stack)

# Current usage: ~100 instances, ~400 watches per node

# These provide comfortable headroom without being excessive

sudo sysctl -w fs.inotify.max_user_instances=1024
sudo sysctl -w fs.inotify.max_user_watches=16384

# To make permanent, add to /etc/sysctl.conf

# fs.inotify.max_user_instances=1024

# fs.inotify.max_user_watches=16384

## Setup

```bash
# Create Kind cluster with disabled CNI
kind create cluster --config kind-config.yaml

# Install all CRDs upfront (best practice: CRDs define APIs, apps implement them)
# This allows faster Helm operations and better version control

# Gateway API CRDs (experimental required for Cilium)
# Cilium's Gateway controller requires TLSRoute and other experimental CRDs
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.2.1/experimental-install.yaml

# Prometheus Operator CRDs (required before Cilium for ServiceMonitors)
kubectl apply -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.87.1/example/prometheus-operator-crd/monitoring.coreos.com_servicemonitors.yaml
kubectl apply --server-side -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.87.1/example/prometheus-operator-crd/monitoring.coreos.com_prometheuses.yaml
kubectl apply --server-side -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.87.1/example/prometheus-operator-crd/monitoring.coreos.com_alertmanagers.yaml
kubectl apply --server-side -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.87.1/example/prometheus-operator-crd/monitoring.coreos.com_podmonitors.yaml
kubectl apply --server-side -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.87.1/example/prometheus-operator-crd/monitoring.coreos.com_prometheusrules.yaml

# cert-manager CRDs (recommended by cert-manager docs for production)
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.19.2/cert-manager.crds.yaml

# Install Cilium as CNI and Gateway controller
# Note: kubeProxyReplacement must be enabled for Gateway API support
helm dependency build ./helm/cilium
helm upgrade --install cilium ./helm/cilium -n kube-system
kubectl wait --for=condition=Ready nodes --all --timeout=300s

# Install Tetragon for security observability
helm dependency build ./helm/tetragon
helm upgrade --install tetragon ./helm/tetragon -n kube-system \
  -f ./helm/ports.yaml \
  -f ./helm/tetragon/values.yaml \
  -f ./helm/tetragon/values-tetragon.yaml
kubectl rollout status -n kube-system ds/tetragon -w

# Install cert-manager for TLS certificate management
helm dependency build ./helm/cert-manager
helm upgrade --install cert-manager ./helm/cert-manager -n cert-manager --create-namespace
kubectl wait --for=condition=Available deployment/cert-manager -n cert-manager --timeout=120s

# Install sealed-secrets for secret management
helm dependency build ./helm/sealed-secrets
helm upgrade --install sealed-secrets ./helm/sealed-secrets -n sealed-secrets --create-namespace

# Install Gateway and test application
helm upgrade --install gateway ./helm/gateway -n gateway --create-namespace
helm upgrade --install http-echo ./helm/http-echo -n http-echo --create-namespace

# Install network policies for security
helm upgrade --install network-policies ./helm/network-policies

# Install monitoring stack (Prometheus + Grafana + Loki + Alloy + Tempo)
# Note: Uses split values files for better organization
# IMPORTANT: All values files must be explicitly specified with -f flags
helm dependency build ./helm/monitoring
helm upgrade --install monitoring ./helm/monitoring -n monitoring --create-namespace \
  -f ./helm/monitoring/values.yaml \
  -f ./helm/monitoring/values-kube-prometheus.yaml \
  -f ./helm/monitoring/values-loki.yaml \
  -f ./helm/monitoring/values-alloy.yaml \
  -f ./helm/monitoring/values-tempo.yaml

# Test the setup
sleep 3
curl -k https://echo.localhost
curl -k https://hubble.localhost
curl -k https://grafana.localhost
```
