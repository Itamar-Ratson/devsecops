# Kubernetes Local Dev Setup

KinD + Cilium (CNI + Gateway) + Gateway API + cert-manager + Sealed Secrets + Hubble + Tetragon + Kyverno + Network Policies + Monitoring (Prometheus + Grafana + Loki + Alloy + Tempo) + Kafka (Strimzi + Kafka UI) + ArgoCD (GitOps)

## Prerequisites

- Docker
- kubectl
- Helm
- KinD
- kubeseal

### Increase inotify limits (required for Hubble mTLS and monitoring stack)

These provide comfortable headroom without being excessive:

```bash
sudo sysctl -w fs.inotify.max_user_instances=1024
sudo sysctl -w fs.inotify.max_user_watches=16384
```

To make permanent, add to /etc/sysctl.conf:

```bash
fs.inotify.max_user_instances=1024
fs.inotify.max_user_watches=16384
```

## Quick Setup

Run the automated setup script:

```bash
./setup.sh
```

The script will:
1. Create a KinD cluster with Cilium CNI
2. Install all infrastructure components
3. Generate an SSH deploy key for ArgoCD (stored at `~/.ssh/argocd-deploy-key`)
4. Create a SealedSecret with the credentials
5. Display the public key to add to GitHub

After the script completes, add the displayed SSH public key as a **deploy key** to your repository:
1. Go to: https://github.com/YOUR-ORG/secure-k8s/settings/keys
2. Click "Add deploy key"
3. Title: `argocd-deploy-key`
4. Paste the public key
5. Leave "Allow write access" **unchecked** (read-only is sufficient)

Once the deploy key is added, ArgoCD will automatically sync all infrastructure applications.

## Access URLs

After setup, the following services are available:

| Service | URL | Credentials |
|---------|-----|-------------|
| Echo (test app) | https://echo.localhost | - |
| Hubble UI | https://hubble.localhost | - |
| Grafana | https://grafana.localhost | admin / prom-operator |
| Kafka UI | https://kafka-ui.localhost | - |
| ArgoCD | https://argocd.localhost | admin / (see below) |

Get ArgoCD admin password:
```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d && echo
```

## GitOps with ArgoCD

Once configured, ArgoCD manages all infrastructure components via GitOps. Applications are defined in `helm/argocd/templates/applications/infrastructure.yaml` with sync waves:

| Wave | Applications |
|------|--------------|
| 1 | Tetragon, Kyverno |
| 2 | Kyverno-policies, Cert-manager |
| 3 | Sealed-secrets, Gateway |
| 4 | Network-policies, HTTP-echo |
| 5 | Strimzi-operator |
| 6 | Kafka |
| 7 | Kafka-ui |
| 8 | Monitoring |

All changes to Helm values in this repository will be automatically synced to the cluster.

## Manual Setup (Reference)

<details>
<summary>Click to expand manual setup commands</summary>

```bash
# Create Kind cluster with disabled CNI
kind create cluster --config kind-config.yaml

# Install all CRDs upfront (best practice: CRDs define APIs, apps implement them)
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.2.1/experimental-install.yaml
kubectl apply -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.87.1/example/prometheus-operator-crd/monitoring.coreos.com_servicemonitors.yaml
kubectl apply --server-side -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.87.1/example/prometheus-operator-crd/monitoring.coreos.com_prometheuses.yaml
kubectl apply --server-side -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.87.1/example/prometheus-operator-crd/monitoring.coreos.com_alertmanagers.yaml
kubectl apply --server-side -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.87.1/example/prometheus-operator-crd/monitoring.coreos.com_podmonitors.yaml
kubectl apply --server-side -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.87.1/example/prometheus-operator-crd/monitoring.coreos.com_prometheusrules.yaml
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.19.2/cert-manager.crds.yaml

# Install Cilium as CNI and Gateway controller
helm dependency build ./helm/cilium
helm upgrade --install cilium ./helm/cilium -n kube-system
kubectl wait --for=condition=Ready nodes --all --timeout=300s

# Install Tetragon for security observability
helm dependency build ./helm/tetragon
helm upgrade --install tetragon ./helm/tetragon -n kube-system \
  -f ./helm/ports.yaml \
  -f ./helm/tetragon/values.yaml \
  -f ./helm/tetragon/values-tetragon.yaml

# Install Kyverno for policy management
helm dependency build ./helm/kyverno
helm upgrade --install kyverno ./helm/kyverno -n kyverno --create-namespace \
  -f ./helm/ports.yaml \
  -f ./helm/kyverno/values.yaml \
  -f ./helm/kyverno/values-kyverno.yaml

# Install Kyverno policies
helm dependency build ./helm/kyverno-policies
helm upgrade --install kyverno-policies ./helm/kyverno-policies -n kyverno \
  -f ./helm/ports.yaml \
  -f ./helm/kyverno-policies/values.yaml

# Install cert-manager
helm dependency build ./helm/cert-manager
helm upgrade --install cert-manager ./helm/cert-manager -n cert-manager --create-namespace \
  -f ./helm/ports.yaml

# Install sealed-secrets
helm dependency build ./helm/sealed-secrets
helm upgrade --install sealed-secrets ./helm/sealed-secrets -n sealed-secrets --create-namespace \
  -f ./helm/ports.yaml

# Install Gateway and test application
helm upgrade --install gateway ./helm/gateway -n gateway --create-namespace
helm upgrade --install http-echo ./helm/http-echo -n http-echo --create-namespace \
  -f ./helm/ports.yaml

# Install network policies
helm upgrade --install network-policies ./helm/network-policies -n kube-system \
  -f ./helm/ports.yaml

# Install Strimzi Kafka Operator (create monitoring namespace first for network policies)
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
helm dependency build ./helm/strimzi-operator
helm upgrade --install strimzi ./helm/strimzi-operator -n strimzi-system --create-namespace \
  -f ./helm/ports.yaml \
  -f ./helm/strimzi-operator/values.yaml \
  -f ./helm/strimzi-operator/values-strimzi.yaml

# Install Kafka cluster
helm upgrade --install kafka ./helm/kafka -n kafka --create-namespace \
  -f ./helm/ports.yaml \
  -f ./helm/kafka/values.yaml

# Install monitoring stack
helm dependency build ./helm/monitoring
helm upgrade --install monitoring ./helm/monitoring -n monitoring --create-namespace \
  -f ./helm/ports.yaml \
  -f ./helm/monitoring/values.yaml \
  -f ./helm/monitoring/values-kube-prometheus.yaml \
  -f ./helm/monitoring/values-loki.yaml \
  -f ./helm/monitoring/values-alloy.yaml \
  -f ./helm/monitoring/values-alloy-consumer.yaml \
  -f ./helm/monitoring/values-tempo.yaml

# Install Kafka UI
helm dependency build ./helm/kafka-ui
helm upgrade --install kafka-ui ./helm/kafka-ui -n kafka-ui --create-namespace \
  -f ./helm/ports.yaml \
  -f ./helm/kafka-ui/values.yaml \
  -f ./helm/kafka-ui/values-kafka-ui.yaml

# Install ArgoCD
helm dependency build ./helm/argocd
helm upgrade --install argocd ./helm/argocd -n argocd --create-namespace \
  -f ./helm/ports.yaml \
  -f ./helm/argocd/values.yaml \
  -f ./helm/argocd/values-argocd.yaml
```

</details>
