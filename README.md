# Kubernetes Local Dev Setup

A zero-trust Kubernetes development environment with comprehensive security and observability.

## Stack Overview

**Infrastructure**<br>
![KinD](https://img.shields.io/badge/KinD-326CE5?style=flat&logo=kubernetes&logoColor=white)
![Cilium](https://img.shields.io/badge/Cilium-F8C517?style=flat&logo=cilium&logoColor=black)
![eBPF](https://img.shields.io/badge/eBPF-FF6600?style=flat&logo=ebpf&logoColor=white)
![Envoy](https://img.shields.io/badge/Envoy-AC6199?style=flat&logo=envoyproxy&logoColor=white)
![WireGuard](https://img.shields.io/badge/WireGuard-88171A?style=flat&logo=wireguard&logoColor=white)
![Gateway API](https://img.shields.io/badge/Gateway_API-326CE5?style=flat&logo=kubernetes&logoColor=white)
![CoreDNS](https://img.shields.io/badge/CoreDNS-253746?style=flat&logo=coredns&logoColor=white)
![cert-manager](https://img.shields.io/badge/cert--manager-0A5CBF?style=flat&logo=letsencrypt&logoColor=white)
![Redis](https://img.shields.io/badge/Redis-DC382D?style=flat&logo=redis&logoColor=white)
![Memcached](https://img.shields.io/badge/Memcached-0769AD?style=flat&logo=memcached&logoColor=white)

**Security**<br>
![Cilium Network Policies](https://img.shields.io/badge/Cilium_Network_Policies-F8C517?style=flat&logo=cilium&logoColor=black)
![Sealed Secrets](https://img.shields.io/badge/Sealed_Secrets-326CE5?style=flat&logo=kubernetes&logoColor=white)
![Vault](https://img.shields.io/badge/Vault-FFEC6E?style=flat&logo=vault&logoColor=black)
![Vault Secrets Operator](https://img.shields.io/badge/Vault_Secrets_Operator-FFEC6E?style=flat&logo=vault&logoColor=black)
![Tetragon](https://img.shields.io/badge/Tetragon-F8C517?style=flat&logo=cilium&logoColor=black)
![Kyverno](https://img.shields.io/badge/Kyverno-FF6F00?style=flat&logo=kubernetes&logoColor=white)
![Trivy](https://img.shields.io/badge/Trivy-1904DA?style=flat&logo=aquasecurity&logoColor=white)

**Observability**<br>
![Hubble](https://img.shields.io/badge/Hubble-F8C517?style=flat&logo=cilium&logoColor=black)
![Prometheus](https://img.shields.io/badge/Prometheus-E6522C?style=flat&logo=prometheus&logoColor=white)
![Alertmanager](https://img.shields.io/badge/Alertmanager-E6522C?style=flat&logo=prometheus&logoColor=white)
![Grafana](https://img.shields.io/badge/Grafana-F46800?style=flat&logo=grafana&logoColor=white)
![Loki](https://img.shields.io/badge/Loki-F46800?style=flat&logo=grafana&logoColor=white)
![Tempo](https://img.shields.io/badge/Tempo-F46800?style=flat&logo=grafana&logoColor=white)
![Alloy](https://img.shields.io/badge/Alloy-F46800?style=flat&logo=grafana&logoColor=white)
![OpenTelemetry](https://img.shields.io/badge/OpenTelemetry-000000?style=flat&logo=opentelemetry&logoColor=white)
![Kube State Metrics](https://img.shields.io/badge/Kube_State_Metrics-326CE5?style=flat&logo=kubernetes&logoColor=white)
![Node Exporter](https://img.shields.io/badge/Node_Exporter-E6522C?style=flat&logo=prometheus&logoColor=white)

**Messaging**<br>
![Kafka](https://img.shields.io/badge/Kafka-231F20?style=flat&logo=apachekafka&logoColor=white)
![Strimzi](https://img.shields.io/badge/Strimzi-191A1C?style=flat&logo=apachekafka&logoColor=white)
![Kafka UI](https://img.shields.io/badge/Kafka_UI-231F20?style=flat&logo=apachekafka&logoColor=white)

**GitOps**<br>
![ArgoCD](https://img.shields.io/badge/ArgoCD-EF7B4D?style=flat&logo=argo&logoColor=white)

**Demo Apps**<br>
![HTTP Echo](https://img.shields.io/badge/HTTP_Echo-326CE5?style=flat&logo=kubernetes&logoColor=white)
![OWASP Juice Shop](https://img.shields.io/badge/OWASP_Juice_Shop-000000?style=flat&logo=owasp&logoColor=white)

## Prerequisites

![Linux](https://img.shields.io/badge/Linux-FCC624?style=flat&logo=linux&logoColor=black)
![Docker](https://img.shields.io/badge/Docker-2496ED?style=flat&logo=docker&logoColor=white)
![docker-compose](https://img.shields.io/badge/docker--compose-2496ED?style=flat&logo=docker&logoColor=white)
![kubectl](https://img.shields.io/badge/kubectl-326CE5?style=flat&logo=kubernetes&logoColor=white)
![Helm](https://img.shields.io/badge/Helm-0F1689?style=flat&logo=helm&logoColor=white)
![KinD](https://img.shields.io/badge/KinD-326CE5?style=flat&logo=kubernetes&logoColor=white)
![kubeseal](https://img.shields.io/badge/kubeseal-326CE5?style=flat&logo=kubernetes&logoColor=white)
![GitHub CLI](https://img.shields.io/badge/gh-181717?style=flat&logo=github&logoColor=white)
![Vault CLI](https://img.shields.io/badge/Vault_CLI-FFEC6E?style=flat&logo=vault&logoColor=black) *(optional, for Transit setup)*

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

### Prerequisites: Environment File

Copy the example environment file and set your secrets:

```bash
cp .env.example .env
# Edit .env with your values (VAULT_TRANSIT_TOKEN, GRAFANA_ADMIN_PASSWORD, etc.)
```

### Create the Cluster

Run the automated setup script:

```bash
./setup.sh
```

The script bootstraps the minimal infrastructure, then **ArgoCD deploys everything else via GitOps**:

**What setup.sh does:**
1. **Clean slate**: Deletes existing cluster and Transit Vault (including volumes)
2. **Transit Vault**: Starts fresh Transit Vault with static IP (172.18.0.100)
3. **KinD cluster**: Creates cluster with Cilium CNI
4. **Sealed-Secrets**: For encrypting ArgoCD repo credentials
5. **ArgoCD**: GitOps controller that deploys all other infrastructure

**What ArgoCD deploys (via sync waves):**
| Wave | Components |
|------|------------|
| 0 | ArgoCD (self-managed) |
| 1 | Tetragon, Kyverno, Trivy, cert-manager, Sealed-secrets, Strimzi, Network-policies |
| 2 | Kyverno-policies, Vault, Kafka |
| 3 | Vault-secrets-operator, Gateway, Kafka-UI |
| 4 | http-echo, juice-shop |
| 5 | Monitoring |

**Note**: Each run of `setup.sh` starts completely fresh - no manual cleanup needed.

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
| Grafana | https://grafana.localhost | (from .env: GRAFANA_ADMIN_USER/PASSWORD) |
| Kafka UI | https://kafka-ui.localhost | - |
| ArgoCD | https://argocd.localhost | admin / (shown in setup.sh output) |
| Vault UI | https://vault.localhost | (root token in K8s secret) |

Get Vault root token (if needed):
```bash
kubectl -n vault get secret vault-root-token -o jsonpath="{.data.token}" | base64 -d && echo
```

## GitOps with ArgoCD

ArgoCD manages all infrastructure components via GitOps. Applications are defined in `helm/argocd/templates/applications/infrastructure.yaml` with optimized sync waves:

| Wave | Applications | Purpose |
|------|--------------|---------|
| 0 | ArgoCD | Self-managed GitOps controller |
| 1 | Tetragon, Kyverno, Trivy, cert-manager, Sealed-secrets, Strimzi, Network-policies | Independent infrastructure (no dependencies) |
| 2 | Kyverno-policies, Vault, Kafka | First-level dependencies |
| 3 | Vault-secrets-operator, Gateway, Kafka-UI | Second-level dependencies |
| 4 | http-echo, juice-shop | Applications (need Gateway) |
| 5 | Monitoring | Last (scrapes all components) |

All changes to Helm values in this repository will be automatically synced to the cluster.

Monitor deployment progress:
```bash
kubectl get applications -n argocd
```

## Custom Secrets (Optional)

Before running `./setup.sh`, you can customize the default secrets in `helm/vault/values.yaml`:

```yaml
bootstrap:
  secrets:
    grafana:
      user: "admin"
      password: "your-secure-password"
    alertmanager:
      criticalWebhook: "https://hooks.slack.com/services/..."
      warningWebhook: "https://hooks.slack.com/services/..."
    argocd:
      passwordHash: "$2a$10$..."  # bcrypt hash
```

Generate ArgoCD password hash:
```bash
htpasswd -nbBC 10 "" your-password | tr -d ':\n'
```

## Troubleshooting

### Clean Slate Reset

If something goes wrong, always start fresh:

```bash
# Full reset - removes cluster, Transit Vault, and all volumes
kind delete cluster --name k8s-dev
docker compose down -v
./setup.sh
```

### Verify Network Policies

Before testing connectivity, check network policies:

```bash
# List all network policies
kubectl get ciliumnetworkpolicies -A

# Watch traffic in real-time
hubble observe --namespace vault

# Test connectivity from a pod
kubectl exec -n vault deploy/vault -- wget -qO- http://target-service
```

## Manual Setup (Reference)

> **Note**: The `setup.sh` script is the recommended way to set up the cluster.
> These manual steps are for reference only.

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
