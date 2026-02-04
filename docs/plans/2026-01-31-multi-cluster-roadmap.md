# Tech Stack Expansion Roadmap

Implementation guide for extending the devsecops project with multi-cluster (KinD + EKS) capabilities.

> **Progress Tracking:** Mark items complete by changing `[ ]` to `[x]` throughout this document.

## Version Summary (Latest Stable as of Jan 2026)

| Component | Version | Source |
|-----------|---------|--------|
| Tailscale Operator | 1.82.0+ | [pkgs.tailscale.com/helmcharts](https://pkgs.tailscale.com/helmcharts) |
| Crossplane | 2.1.0 | [charts.crossplane.io/stable](https://charts.crossplane.io/stable) |
| Upbound AWS Providers | v2.3.0 | [Upbound Marketplace](https://marketplace.upbound.io/providers/upbound/provider-family-aws/latest) |
| function-patch-and-transform | v0.8.2 | [GitHub](https://github.com/crossplane-contrib/function-patch-and-transform) |
| function-auto-ready | v0.6.0 | [GitHub](https://github.com/crossplane-contrib/function-auto-ready) |
| Karpenter | 1.8.1 | [public.ecr.aws/karpenter](https://gallery.ecr.aws/karpenter/karpenter) |
| KEDA | 2.18.3 | [kedacore.github.io/charts](https://kedacore.github.io/charts) |
| Headlamp | 0.28.0 | [kubernetes-sigs.github.io/headlamp](https://kubernetes-sigs.github.io/headlamp/) (v0.39.0 has bugs) |
| kube-oidc-proxy | 0.3.0 | [github.com/jetstack/kube-oidc-proxy](https://github.com/jetstack/kube-oidc-proxy) |
| Backstage | 2.6.3 | [backstage.github.io/charts](https://backstage.github.io/charts) |
| Cloudflare Tunnel (cloudflared) | Chart: 2.2.5+, App: 2026.1.2 | [community-charts](https://community-charts.github.io/helm-charts), [GitHub](https://github.com/cloudflare/cloudflared/releases) |
| Upbound Azure Providers | v1.x.x | [Upbound Marketplace](https://marketplace.upbound.io/providers/upbound/provider-family-azure/latest) |

---

## Resource Budget (KinD Local)

Current system: 16GB RAM, 8 vCPUs, ~3GB available

| Component | Estimated RAM | Notes |
|-----------|---------------|-------|
| Tailscale | ~100-200MB | Operator + subnet router |
| Cloudflare Tunnel | ~100-200MB | 2 replicas |
| Crossplane + Providers | ~400-600MB | Core + AWS + Azure providers |
| Headlamp | ~100-200MB | Single replica |
| Backstage | ~300-500MB | PostgreSQL on RDS |
| **Total New** | **~1.0-1.7GB** | Fits in 3GB available |

**If memory constrained:** Disable Tempo (~300-500MB savings)

---

## Architecture Overview

```
                              ┌─────────────────────┐
                              │   Cloudflare Edge   │
                              │  (external access)  │
                              └──────────┬──────────┘
                                         │ Tunnels (outbound-only)
        ┌────────────────────────────────┼────────────────────────────────┐
        │                                │                                │
        ▼                                ▼                                ▼
┌───────────────────┐  ┌───────────────────────────────┐  ┌───────────────────┐
│   KinD (Hub)      │  │         EKS (AWS Spoke)       │  │   AKS (Azure Spoke)│
│                   │  │                               │  │                   │
│ ┌───────────────┐ │  │ ┌───────────────────────────┐ │  │ ┌───────────────┐ │
│ │ cloudflared   │ │  │ │ cloudflared               │ │  │ │ cloudflared   │ │
│ │ ArgoCD        │ │  │ │ Cilium (chaining+VPC CNI) │ │  │ │ Cilium (Azure)│ │
│ │ Vault         │ │  │ │ Karpenter (EC2NodeClass)  │ │  │ │ NAP/Karpenter │ │
│ │ Monitoring    │ │  │ │ Tetragon, Kyverno, KEDA   │ │  │ │ (AKSNodeClass)│ │
│ │ Crossplane    │ │  │ │ Alloy → pushes to KinD    │ │  │ │ Tetragon, etc │ │
│ │ Headlamp      │ │  │ └───────────────────────────┘ │  │ └───────────────┘ │
│ │ Backstage     │ │  │                               │  │                   │
│ └───────────────┘ │  └───────────────┬───────────────┘  └─────────┬─────────┘
└─────────┬─────────┘                  │                            │
          │                            │                            │
          └────────────────────────────┴────────────────────────────┘
                                 Tailscale
                          (private cross-cluster mesh)

Traffic Flow:
  - External: Internet → Cloudflare → cloudflared tunnel → Gateway → Apps
  - Internal: KinD ↔ EKS ↔ AKS via Tailscale (private)
  - Metrics/Logs: Spokes push to KinD monitoring stack via Tailscale
```

---

## Implementation Order

| Phase | Component | Sync Wave | Depends On | Status |
|-------|-----------|-----------|------------|--------|
| 1 | Transit Vault External Secrets Store | - | - | [x] Complete |
| 2 | Headlamp + kube-oidc-proxy | 5 | Phase 1 (uses Transit Vault for OIDC secret) | [x] Complete |
| 3 | Tailscale | 1 | - | [ ] |
| 4 | Cloudflare Tunnel (KinD) | 1 | - | [ ] |
| 5 | Crossplane (core only) | 1 | - | [ ] |
| 6 | EKS + AWS Providers + Spoke Agents | 2 | Crossplane, Tailscale | [ ] |
| 7 | Backstage | 5 | Crossplane (for RDS) | [ ] |
| 8 | AKS + Azure Providers + Spoke Agents | 2 | Crossplane, Tailscale | [ ] |

**Key design:**
- Phase 1 first = migrate secrets to Transit Vault, Terraform-ready architecture
- Headlamp second = immediate visibility, auto-discovers clusters via ArgoCD
- Cloud providers installed with their respective clusters (modular)
- Each cloud phase is self-contained (can skip AKS if not needed)

**Phase 1 details:** See [Phase 1: Transit Vault External Secrets Store](./2026-01-31-phase1-transit-vault-secrets.md)

**Removed from scope:**
- **Cilium Cluster Mesh** - Tailscale provides cross-cluster connectivity. Cluster Mesh requires Cilium as primary CNI, which conflicts with Karpenter's need for cloud-native CNI (AWS VPC CNI / Azure CNI).

**Note:** Phase sections below are organized by topic. Follow the implementation order table above.

---

## Phase 1: Transit Vault External Secrets Store

### Purpose
Migrate static/bootstrap secrets from in-cluster Vault to Transit Vault (external Docker container). This makes secrets persist across cluster recreations and prepares the architecture for Terraform migration.

### Key Changes
- Enable KV v2 engine on Transit Vault (in addition to Transit engine)
- Configure Kubernetes auth on Transit Vault so VSO can authenticate
- Seed all static secrets to Transit Vault instead of in-cluster Vault
- Update all VaultStaticSecret resources to pull from Transit Vault
- Simplify in-cluster Vault bootstrap job (remove secret seeding)

### Benefits
- Secrets survive cluster recreation (no re-seeding needed)
- setup.sh becomes simpler (no kubectl create secret commands)
- Terraform-ready (vault provider can manage Transit Vault)
- Single external source of truth for static secrets
- In-cluster Vault available for future dynamic secrets (AWS, DB, PKI)

### Detailed Plan
See [Phase 1: Transit Vault External Secrets Store](./2026-01-31-phase1-transit-vault-secrets.md)

---

## Phase 2: Headlamp + kube-oidc-proxy ✅ COMPLETE

### Purpose
Multi-cluster Kubernetes dashboard/UI with OIDC authentication. Uses kube-oidc-proxy to validate OIDC tokens without requiring API server configuration changes.

### Architecture
```
Browser → Headlamp (in-cluster) → kube-oidc-proxy → Kubernetes API
                ↓
            Keycloak (OIDC)
```

- **kube-oidc-proxy** validates OIDC tokens and impersonates users to the API server
- No API server OIDC configuration required (works with any K8s distribution)
- User permissions based on Keycloak group membership (RBAC)

### Implementation Details

See [docs/HEADLAMP-OIDC-ISSUE.md](../HEADLAMP-OIDC-ISSUE.md) for complete documentation.

**Key Components:**
1. **kube-oidc-proxy** - OIDC token validation proxy
2. **Combined CA Bundle** - trust-manager bundle with Kubernetes + gateway CA
3. **Custom Projected Volume** - Headlamp uses custom ServiceAccount mount with combined CA
4. **Network Policies** - Bidirectional rules on port 8443 (pod port)

**Helm Charts Created:**
```
helm/headlamp/           # Headlamp dashboard
helm/kube-oidc-proxy/    # OIDC proxy for API authentication
```

**Ports (helm/ports.yaml):**
```yaml
ports:
  headlamp:
    http: 4466
  kubeOidcProxy:
    https: 8443
```

**Version Note:** Using Headlamp v0.28.0. Version v0.39.0 has bugs:
- `"failed to append ca cert to pool"` - CA handling issues
- `"refreshing token: key not found"` - Refresh token bug

**Keycloak Client Configuration:**
- Client ID: `headlamp`
- Client Protocol: `openid-connect`
- Access Type: `confidential`
- Valid Redirect URIs: `https://headlamp.localhost/*`
- Test user: `testuser` / `testuser` (member of `admins` group)

**Sync Wave:** 5

---

## Phase 3: Tailscale

### Purpose
Network connectivity fabric between KinD (behind NAT) and cloud clusters.

### Specifications

**Helm Chart Structure:**
```
helm/tailscale/
├── Chart.yaml
├── values.yaml
├── values-tailscale.yaml
└── templates/
    ├── networkpolicy.yaml
    └── operator.yaml (if needed beyond upstream)
```

**Chart.yaml Dependencies:**
```yaml
apiVersion: v2
name: tailscale
version: 0.1.0
dependencies:
  - name: tailscale-operator
    version: "1.82.0"  # Check https://pkgs.tailscale.com/helmcharts/index.yaml for latest
    repository: "https://pkgs.tailscale.com/helmcharts"
```

**Ports to add to helm/ports.yaml:**
```yaml
ports:
  tailscale:
    metrics: 9001
    # Tailscale uses outbound connections, minimal inbound ports
```

**Network Policies:**
- Egress: Allow to Tailscale coordination servers (controlplane.tailscale.com)
- Egress: Allow UDP for WireGuard (STUN/relay servers)
- Ingress: Prometheus scrape on metrics port

**Sync Wave:** 1 (independent infrastructure)

**Prerequisites:**
- Tailscale account
- Auth key (store as SealedSecret)
- Decide: Operator mode vs Subnet Router mode

**Key Configuration (values-tailscale.yaml):**
```yaml
tailscale-operator:
  oauth:
    clientId: ""      # From Tailscale admin
    clientSecret: ""  # SealedSecret reference
  # Subnet router to expose pod CIDR
  subnetRouter:
    enabled: true
    routes:
      - "10.244.0.0/16"  # KinD pod CIDR
```

**ArgoCD Application:** `helm/argocd/templates/applications/tailscale.yaml`

---

## Phase 4: Cloudflare Tunnel

### Purpose
External ingress without ALB. Zero-trust, outbound-only tunnels from cluster to Cloudflare Edge.

### Specifications

**Helm Chart Structure:**
```
helm/cloudflared/
├── Chart.yaml
├── values.yaml
├── values-cloudflared.yaml
└── templates/
    ├── networkpolicy.yaml
    ├── servicemonitor.yaml
    └── tunnel-secret.yaml      # SealedSecret for tunnel credentials
```

**Chart.yaml Dependencies:**
```yaml
apiVersion: v2
name: cloudflared
version: 0.1.0
appVersion: "2026.1.2"  # Latest cloudflared binary
dependencies:
  - name: cloudflared
    version: "2.2.5"  # Latest chart - check for updates
    repository: "https://community-charts.github.io/helm-charts"
```

**Override image to latest cloudflared (values-cloudflared.yaml):**
```yaml
cloudflared:
  image:
    repository: cloudflare/cloudflared
    tag: "2026.1.2"  # Override to latest
```

**Ports to add to helm/ports.yaml:**
```yaml
ports:
  cloudflared:
    metrics: 9090
    # No inbound ports - outbound-only tunnel
```

**Network Policies:**
- Egress: Allow to Cloudflare IPs (can use FQDN: `*.cloudflare.com`)
- Egress: Allow to internal Gateway/services
- Ingress: Prometheus scrape on metrics port
- No public ingress needed (outbound-only)

**Sync Wave:** 1 (independent infrastructure)

**Prerequisites:**
- Cloudflare account (free tier works)
- Domain added to Cloudflare
- Tunnel created via `cloudflared tunnel create <name>`
- Tunnel credentials JSON (store as SealedSecret)

**Key Configuration (values-cloudflared.yaml):**
```yaml
cloudflared:
  replicaCount: 2  # HA

  tunnel:
    # Reference existing tunnel credentials from SealedSecret
    existingSecret: cloudflared-tunnel-credentials

  config:
    ingress:
      # Route traffic to Cilium Gateway
      - hostname: "*.yourdomain.com"
        service: http://cilium-gateway.gateway.svc:80
      - hostname: argocd.yourdomain.com
        service: http://argocd-server.argocd.svc:80
      - hostname: grafana.yourdomain.com
        service: http://grafana.monitoring.svc:3000
      # Catch-all (required)
      - service: http_status:404

  resources:
    requests:
      memory: 32Mi
      cpu: 10m
    limits:
      memory: 128Mi
      cpu: 100m
```

**Integration with Cilium Gateway:**
```
Internet → Cloudflare Edge → cloudflared pod → Cilium Gateway → HTTPRoute → Service
```

Cloudflare Tunnel replaces:
- AWS ALB (no load balancer costs)
- Public IPs on nodes
- Complex security group rules
- SSL certificate management (Cloudflare handles it)

**ArgoCD Application:** `helm/argocd/templates/applications/cloudflared.yaml`

---

## Phase 5: Crossplane (Core)

### Purpose
Infrastructure as Code foundation. Installs Crossplane core only - cloud providers are added with their respective clusters.

### Specifications

**Helm Chart Structure:**
```
helm/crossplane/
├── Chart.yaml
├── values.yaml
├── values-crossplane.yaml
└── templates/
    ├── networkpolicy.yaml
    ├── servicemonitor.yaml
    └── aws-provider.yaml (ProviderConfig for AWS)
```

**Chart.yaml Dependencies:**
```yaml
apiVersion: v2
name: crossplane
version: 0.1.0
dependencies:
  - name: crossplane
    version: "2.1.0"  # Latest stable Crossplane v2
    repository: "https://charts.crossplane.io/stable"
```

**Crossplane v2 Changes:**
- New `Function` based compositions (replacing inline patch-and-transform)
- XRDs use `apiextensions.crossplane.io/v2` with new `scope` field (defaults to Namespaced)
- Compositions still use `apiextensions.crossplane.io/v1` with `mode: Pipeline`
- Providers/Functions still use `pkg.crossplane.io/v1`
- Optional namespaced managed resources with `.m.` domain (e.g., `s3.aws.m.upbound.io`)
- Better status conditions and events

**XRD Example (v2 API with scope):**
```yaml
apiVersion: apiextensions.crossplane.io/v2
kind: CompositeResourceDefinition
metadata:
  name: xeksclusters.infrastructure.devsecops
spec:
  group: infrastructure.devsecops
  names:
    kind: XEKSCluster
    plural: xeksclusters
  scope: Cluster  # or Namespaced (default in v2)
  versions:
    - name: v1alpha1
      served: true
      referenceable: true
      schema:
        openAPIV3Schema:
          type: object
          properties:
            spec:
              type: object
              properties:
                parameters:
                  type: object
                  # ... cluster parameters
```

**Ports to add to helm/ports.yaml:**
```yaml
ports:
  crossplane:
    metrics: 8080
    webhooks: 9443
```

**Network Policies:**
- Egress: AWS APIs (*.amazonaws.com) - or via NAT
- Egress: Kubernetes API server
- Ingress: Prometheus scrape on metrics port
- Ingress: Webhook traffic from API server

**Sync Wave:** 1 (independent infrastructure)

**Prerequisites:**
- AWS credentials via Vault AWS secrets engine (dynamic, auto-rotating)
- Using Upbound AWS Provider (family providers for modular installation)

**Key Configuration (values-crossplane.yaml):**
```yaml
crossplane:
  metrics:
    enabled: true
  resourcesCrossplane:
    requests:
      cpu: 100m
      memory: 256Mi
    limits:
      cpu: 500m
      memory: 512Mi
```

**ArgoCD Application:** `helm/argocd/templates/applications/crossplane.yaml`

---

## Phase 6: EKS + AWS Providers + Spoke Agents

### Purpose
First cloud cluster: AWS EKS with Karpenter. Includes AWS providers, EKS cluster, and all spoke agents.

### AWS Providers

**Helm Chart Structure:**
```
helm/crossplane-aws/
├── Chart.yaml
├── values.yaml
├── values-aws-provider.yaml
└── templates/
    ├── provider.yaml           # AWS Provider installation
    ├── providerconfig.yaml     # AWS credentials config
    ├── functions.yaml          # Crossplane v2 Functions (function-patch-and-transform, etc.)
    ├── networkpolicy.yaml
    └── compositions/
        ├── eks-cluster.yaml    # XRD + Composition for EKS (using Functions)
        ├── vpc.yaml            # VPC Composition
        └── iam.yaml            # IAM roles for EKS
```

**Crossplane v2 Functions (templates/functions.yaml):**
```yaml
# pkg.crossplane.io/v1 is still correct for Functions in Crossplane v2
apiVersion: pkg.crossplane.io/v1
kind: Function
metadata:
  name: function-patch-and-transform
spec:
  package: xpkg.upbound.io/crossplane-contrib/function-patch-and-transform:v0.8.2
---
apiVersion: pkg.crossplane.io/v1
kind: Function
metadata:
  name: function-auto-ready
spec:
  package: xpkg.upbound.io/crossplane-contrib/function-auto-ready:v0.6.0
```

**Provider Installation (templates/provider.yaml):**
```yaml
# pkg.crossplane.io/v1 is still correct in Crossplane v2
apiVersion: pkg.crossplane.io/v1
kind: Provider
metadata:
  name: provider-aws-eks
spec:
  package: xpkg.upbound.io/upbound/provider-aws-eks:v2.3.0
---
apiVersion: pkg.crossplane.io/v1
kind: Provider
metadata:
  name: provider-aws-ec2
spec:
  package: xpkg.upbound.io/upbound/provider-aws-ec2:v2.3.0
---
apiVersion: pkg.crossplane.io/v1
kind: Provider
metadata:
  name: provider-aws-iam
spec:
  package: xpkg.upbound.io/upbound/provider-aws-iam:v2.3.0
# Start with 3 providers (eks, ec2, iam). Add vpc/rds later if needed.
# Upbound AWS provider family v2.3.0 - support until Dec 2026
```

**AWS Credentials via Vault:**
```yaml
# ProviderConfig referencing Vault-injected secret
apiVersion: aws.upbound.io/v1beta1
kind: ProviderConfig
metadata:
  name: aws-provider
spec:
  credentials:
    source: Secret
    secretRef:
      namespace: crossplane-system
      name: aws-credentials  # Created by VSO from Vault
      key: credentials
```

**Sync Wave:** 2 (depends on Crossplane)

**EKS Composition Key Features (Crossplane v2 with Functions):**
```yaml
apiVersion: apiextensions.crossplane.io/v1
kind: Composition
metadata:
  name: eks-cluster
spec:
  compositeTypeRef:
    apiVersion: infrastructure.devsecops/v1alpha1
    kind: XEKSCluster
  mode: Pipeline
  pipeline:
    - step: patch-and-transform
      functionRef:
        name: function-patch-and-transform
      input:
        apiVersion: pt.fn.crossplane.io/v1beta1
        kind: Resources
        resources:
          - name: vpc
            base:
              apiVersion: ec2.aws.upbound.io/v1beta1
              kind: VPC
              # ... VPC config
          - name: eks-cluster
            base:
              apiVersion: eks.aws.upbound.io/v1beta1
              kind: Cluster
              # ... EKS config with Cilium chaining support
    - step: auto-ready
      functionRef:
        name: function-auto-ready
```

**Composition Features:**
- EKS cluster with specific Kubernetes version
- Managed node groups (for Karpenter bootstrap)
- VPC CNI addon minimal (for Cilium chaining)
- OIDC provider for IRSA
- ArgoCD cluster secret output (for hub registration)

### EKS Cluster (Crossplane Claim)

**Helm Chart Structure:**
```
helm/eks-cluster/
├── Chart.yaml
├── values.yaml
├── values-eks.yaml
└── templates/
    ├── claim.yaml              # XR Claim for EKS
    ├── argocd-cluster.yaml     # Register EKS in ArgoCD
    └── networkpolicy.yaml
```

**Claim Example (templates/claim.yaml):**
```yaml
apiVersion: infrastructure.devsecops/v1alpha1
kind: EKSCluster
metadata:
  name: eks-spoke
  namespace: crossplane-system
spec:
  parameters:
    region: eu-west-1
    kubernetesVersion: "1.29"
    nodeGroups:
      - name: system
        instanceTypes: ["t3.medium"]
        desiredSize: 2
        minSize: 1
        maxSize: 3
    cilium:
      enabled: true
      chainingMode: aws-cni
    tailscale:
      enabled: true
      authKeySecret: tailscale-auth  # SealedSecret
    addons:
      - karpenter
      - keda
```

**ArgoCD Cluster Registration:**
The Composition should output a Secret that ArgoCD can use:
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: eks-spoke-cluster
  namespace: argocd
  labels:
    argocd.argoproj.io/secret-type: cluster
    role: spoke
type: Opaque
stringData:
  name: eks-spoke
  server: https://xxx.eks.amazonaws.com
  config: |
    {
      "execProviderConfig": {
        "command": "argocd-k8s-auth",
        "args": ["aws", "--cluster-name", "eks-spoke"]
      }
    }
```

**Sync Wave:** 2 (depends on Crossplane AWS Provider)

**Post-Provisioning:** EKS spoke agents deployed via ArgoCD ApplicationSet

---

### EKS Spoke Agents

Lightweight agents on EKS that connect back to KinD hub services.

**ApplicationSet for Spoke Components:**
```yaml
# helm/argocd/templates/applications/spoke-agents.yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: spoke-agents
  namespace: argocd
spec:
  generators:
    - matrix:
        generators:
          - clusters:
              selector:
                matchLabels:
                  role: spoke
          - list:
              elements:
                - name: cloudflared-spoke
                  path: helm/cloudflared
                  wave: "1"
                  values: values-eks.yaml
                - name: cilium-spoke
                  path: helm/cilium
                  wave: "1"
                  values: values-eks.yaml
                - name: tetragon-spoke
                  path: helm/tetragon
                  wave: "1"
                  values: values-eks.yaml
                - name: kyverno-spoke
                  path: helm/kyverno
                  wave: "1"
                  values: values-eks.yaml
                - name: alloy-spoke
                  path: helm/monitoring
                  wave: "2"
                  values: values-alloy-spoke.yaml
                - name: vso-spoke
                  path: helm/vault-secrets-operator
                  wave: "2"
                  values: values-eks.yaml
                - name: karpenter
                  path: helm/karpenter
                  wave: "3"
                  values: values-karpenter.yaml
                - name: keda
                  path: helm/keda
                  wave: "3"
                  values: values-keda.yaml
                - name: argo-rollouts-spoke
                  path: helm/argo-rollouts
                  wave: "3"
                  values: values-eks.yaml
  template:
    metadata:
      name: '{{name}}-{{nameNormalized}}'
      annotations:
        argocd.argoproj.io/sync-wave: '{{wave}}'
    spec:
      project: default
      source:
        repoURL: <repo-url>
        path: '{{path}}'
        helm:
          valueFiles:
            - ../ports.yaml
            - values.yaml
            - '{{values}}'
      destination:
        server: '{{server}}'
        namespace: '{{name}}'
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
        syncOptions:
          - CreateNamespace=true
```

### Spoke-Specific Values Files Needed

**helm/cilium/values-eks.yaml:**
```yaml
cilium:
  cni:
    chainingMode: aws-cni
    exclusive: false
  enableIPv4Masquerade: false
  tunnel: disabled
  endpointRoutes:
    enabled: true
  hubble:
    enabled: true
    relay:
      enabled: true
  cluster:
    name: eks-spoke
```

**helm/monitoring/values-alloy-spoke.yaml:**
```yaml
# Only Alloy, pushes to KinD
alloy:
  enabled: true
  # Remote write to KinD Prometheus via Tailscale
  remoteWrite:
    - url: http://prometheus.monitoring.svc.kind:9090/api/v1/write  # Via Tailscale
  # Push logs to KinD Loki
  lokiUrl: http://loki.monitoring.svc.kind:3100/loki/api/v1/push
  # Push traces to KinD Tempo
  tempoUrl: http://tempo.monitoring.svc.kind:4317

# Disable all other monitoring components
kube-prometheus-stack:
  enabled: false
loki:
  enabled: false
tempo:
  enabled: false
```

**helm/vault-secrets-operator/values-eks.yaml:**
```yaml
vault-secrets-operator:
  defaultVaultConnection:
    enabled: true
    address: http://vault.vault.svc.kind:8200  # Via Tailscale
    skipTLSVerify: false
```

**helm/cloudflared/values-eks.yaml:**
```yaml
cloudflared:
  image:
    repository: cloudflare/cloudflared
    tag: "2026.1.2"

  replicaCount: 2

  tunnel:
    # Separate tunnel for EKS (different from KinD tunnel)
    existingSecret: cloudflared-eks-tunnel-credentials

  config:
    ingress:
      # EKS-specific hostnames (production/staging)
      - hostname: "app.yourdomain.com"
        service: http://cilium-gateway.gateway.svc:80
      - hostname: "api.yourdomain.com"
        service: http://cilium-gateway.gateway.svc:80
      # Catch-all
      - service: http_status:404

  resources:
    requests:
      memory: 32Mi
      cpu: 10m
    limits:
      memory: 128Mi
      cpu: 100m
```

### New Charts Needed

**helm/karpenter/:**
```
helm/karpenter/
├── Chart.yaml
├── values.yaml
├── values-karpenter.yaml
└── templates/
    ├── networkpolicy.yaml
    ├── servicemonitor.yaml
    ├── default-nodepool.yaml    # NodePool + EC2NodeClass
    └── provisioner.yaml
```

**Chart.yaml:**
```yaml
apiVersion: v2
name: karpenter
version: 0.1.0
dependencies:
  - name: karpenter
    version: "1.8.1"  # Latest stable
    repository: "oci://public.ecr.aws/karpenter"
```

**Ports:**
```yaml
ports:
  karpenter:
    metrics: 8080
    healthProbe: 8081
    webhooks: 8443
```

---

**helm/keda/:**
```
helm/keda/
├── Chart.yaml
├── values.yaml
├── values-keda.yaml
└── templates/
    ├── networkpolicy.yaml
    └── servicemonitor.yaml
```

**Chart.yaml:**
```yaml
apiVersion: v2
name: keda
version: 0.1.0
dependencies:
  - name: keda
    version: "2.18.3"  # Latest stable
    repository: "https://kedacore.github.io/charts"
```

**Ports:**
```yaml
ports:
  keda:
    metrics: 8080
    metricsService: 9666
    webhooks: 9443
```

---

## Phase 7: Backstage

### Purpose
Developer portal - service catalog, documentation, scaffolding.

### Specifications

**Helm Chart Structure:**
```
helm/backstage/
├── Chart.yaml
├── values.yaml
├── values-backstage.yaml
└── templates/
    ├── networkpolicy.yaml
    ├── httproute.yaml
    ├── servicemonitor.yaml
    └── app-config.yaml         # Backstage configuration ConfigMap
```

**Chart.yaml:**
```yaml
apiVersion: v2
name: backstage
version: 0.1.0
dependencies:
  - name: backstage
    version: "2.6.3"  # Latest stable
    repository: "https://backstage.github.io/charts"
```

**Database:** Crossplane provisions RDS PostgreSQL.

**Ports:**
```yaml
ports:
  backstage:
    http: 7007
```

**Key Configuration (values-backstage.yaml):**
```yaml
backstage:
  appConfig:
    app:
      title: DevSecOps Portal
    backend:
      database:
        client: pg
        connection:
          host: ${POSTGRES_HOST}
          port: ${POSTGRES_PORT}
          user: ${POSTGRES_USER}
          password: ${POSTGRES_PASSWORD}
    auth:
      environment: production
      providers:
        oidc:
          production:
            metadataUrl: https://keycloak.yourdomain.com/realms/devsecops/.well-known/openid-configuration
            clientId: backstage
            clientSecret: ${OIDC_CLIENT_SECRET}
            prompt: auto
            scope: "openid profile email groups"
    kubernetes:
      serviceLocatorMethod:
        type: multiTenant
      clusterLocatorMethods:
        # Dynamic discovery from ArgoCD cluster secrets
        - type: argocd
          argocd:
            namespace: argocd
            labelSelector: argocd.argoproj.io/secret-type=cluster
```

**Dynamic Discovery:** Backstage Kubernetes plugin reads cluster credentials from ArgoCD cluster secrets. New clusters automatically appear when registered with ArgoCD.

**Keycloak Client Setup:**
- Client ID: `backstage`
- Client Protocol: `openid-connect`
- Access Type: `confidential`
- Valid Redirect URIs: `https://backstage.yourdomain.com/*`

**RDS via Crossplane (add to crossplane-aws compositions):**
```yaml
apiVersion: rds.aws.upbound.io/v1beta1
kind: Instance
metadata:
  name: backstage-db
spec:
  forProvider:
    engine: postgres
    engineVersion: "15"
    instanceClass: db.t3.micro
    allocatedStorage: 20
    dbName: backstage
```

**Sync Wave:** 5 (after Crossplane provisions RDS)

**Resource Considerations:**
- Backstage: ~300-500MB
- RDS runs on AWS, not locally

---

## Phase 8: AKS + Azure Providers + Spoke Agents

### Purpose
Second cloud cluster: Azure AKS with NAP (Karpenter). Includes Azure providers, AKS cluster, and all spoke agents.

### Specifications

**Add Azure Providers to helm/crossplane-aws/ (rename to crossplane-cloud/):**
```yaml
apiVersion: pkg.crossplane.io/v1
kind: Provider
metadata:
  name: provider-azure-containerservice
spec:
  package: xpkg.upbound.io/upbound/provider-azure-containerservice:v1.x.x
---
apiVersion: pkg.crossplane.io/v1
kind: Provider
metadata:
  name: provider-azure-compute
spec:
  package: xpkg.upbound.io/upbound/provider-azure-compute:v1.x.x
---
apiVersion: pkg.crossplane.io/v1
kind: Provider
metadata:
  name: provider-azure-network
spec:
  package: xpkg.upbound.io/upbound/provider-azure-network:v1.x.x
```

**Azure Credentials via Vault:**
```bash
# Enable Azure secrets engine
vault secrets enable azure

# Configure Azure credentials
vault write azure/config \
  subscription_id=$AZURE_SUBSCRIPTION_ID \
  tenant_id=$AZURE_TENANT_ID \
  client_id=$AZURE_CLIENT_ID \
  client_secret=$AZURE_CLIENT_SECRET

# Create role for Crossplane
vault write azure/roles/crossplane-role \
  azure_roles=-<<EOF
  [
    {
      "role_name": "Contributor",
      "scope": "/subscriptions/$AZURE_SUBSCRIPTION_ID"
    }
  ]
EOF
```

**AKS Composition (helm/crossplane-cloud/templates/compositions/aks-cluster.yaml):**
```yaml
apiVersion: apiextensions.crossplane.io/v1
kind: Composition
metadata:
  name: aks-cluster
spec:
  compositeTypeRef:
    apiVersion: infrastructure.devsecops/v1alpha1
    kind: XAKSCluster
  mode: Pipeline
  pipeline:
    - step: patch-and-transform
      functionRef:
        name: function-patch-and-transform
      input:
        apiVersion: pt.fn.crossplane.io/v1beta1
        kind: Resources
        resources:
          - name: resource-group
            base:
              apiVersion: azure.upbound.io/v1beta1
              kind: ResourceGroup
          - name: aks-cluster
            base:
              apiVersion: containerservice.azure.upbound.io/v1beta1
              kind: KubernetesCluster
              spec:
                forProvider:
                  defaultNodePool:
                    - name: system
                      vmSize: Standard_D2s_v3
                      nodeCount: 2
    - step: auto-ready
      functionRef:
        name: function-auto-ready
```

**AKS Spoke Agents (add to ApplicationSet):**
```yaml
# Add to spoke-agents.yaml generator list
- name: cloudflared-spoke
  path: helm/cloudflared
  wave: "1"
  values: values-aks.yaml
- name: cilium-spoke
  path: helm/cilium
  wave: "1"
  values: values-aks.yaml
- name: tetragon-spoke
  path: helm/tetragon
  wave: "1"
  values: values-aks.yaml
- name: kyverno-spoke
  path: helm/kyverno
  wave: "1"
  values: values-aks.yaml
- name: alloy-spoke
  path: helm/monitoring
  wave: "2"
  values: values-alloy-spoke.yaml
- name: vso-spoke
  path: helm/vault-secrets-operator
  wave: "2"
  values: values-aks.yaml
- name: keda
  path: helm/keda
  wave: "3"
  values: values-aks.yaml
# Note: Karpenter on AKS uses NAP (managed addon) or AKSNodeClass
```

**helm/karpenter/values-aks.yaml:**
```yaml
# AKS uses Node Auto-Provisioning (NAP) - Karpenter as managed addon
# Or self-hosted with AKSNodeClass
karpenter:
  controller:
    env:
      - name: CLOUD_PROVIDER
        value: azure

# AKSNodeClass instead of EC2NodeClass
aksNodeClass:
  enabled: true
  spec:
    imageFamily: Ubuntu2204
```

**helm/cilium/values-aks.yaml:**
```yaml
cilium:
  cni:
    chainingMode: azure-cni  # Azure equivalent
    exclusive: false
  enableIPv4Masquerade: false
  tunnel: disabled
  hubble:
    enabled: true
    relay:
      enabled: true
  cluster:
    name: aks-spoke
```

**helm/cloudflared/values-aks.yaml:**
```yaml
cloudflared:
  image:
    repository: cloudflare/cloudflared
    tag: "2026.1.2"
  replicaCount: 2
  tunnel:
    existingSecret: cloudflared-aks-tunnel-credentials
  config:
    ingress:
      - hostname: "aks-app.yourdomain.com"
        service: http://cilium-gateway.gateway.svc:80
      - service: http_status:404
```

---

## Summary: Files to Create

### Phase 1: Transit Vault External Secrets Store ✅ COMPLETE
**Scripts Modified:**
- [x] `scripts/transit-setup.sh` - Enable KV v2 engine
- [x] `scripts/setup.sh` - Add Transit Vault K8s auth + secret seeding, remove in-cluster secret creation

**Helm Charts Modified:**
- [x] `helm/vault-secrets-operator/values.yaml` - Add transitVault.address config
- [x] `helm/vault-secrets-operator/templates/transit-vault-connection.yaml` - NEW: VaultConnection for Transit Vault
- [x] `helm/vault-secrets-operator/templates/transit-vault-auth.yaml` - NEW: VaultAuth for Transit Vault
- [x] `helm/argocd/templates/vault-secrets.yaml` - Update vaultAuthRef (disabled, uses kubectl secrets)
- [x] `helm/monitoring/templates/vault-secrets.yaml` - Update vaultAuthRef to Transit Vault
- [x] `helm/vault/templates/vault-secrets.yaml` - Update vaultAuthRef to Transit Vault
- [x] `helm/keycloak/templates/vault-secrets.yaml` - Update vaultAuthRef to Transit Vault
- [x] `helm/vault/templates/job-bootstrap.yaml` - Remove secret seeding (keep init + auth config)
- [x] `helm/keycloak/templates/realm-config.yaml` - Fix placeholder syntax for Keycloak 24
- [x] `helm/monitoring/values-kube-prometheus.yaml` - Enable cert-manager for admission webhooks

### Phase 2: Headlamp + kube-oidc-proxy ✅ COMPLETE
- [x] `helm/headlamp/` - Headlamp UI with OIDC via Keycloak
- [x] `helm/kube-oidc-proxy/` - OIDC token validation proxy
- [x] `helm/trust-manager/templates/ca-bundle.yaml` - Combined CA (Kubernetes + gateway)
- [x] `helm/argocd/templates/applications/headlamp.yaml` - ArgoCD Application (Wave 5)
- [x] `helm/argocd/templates/applications/kube-oidc-proxy.yaml` - ArgoCD Application (Wave 5)
- [x] `helm/ports.yaml` - Added headlamp.http (4466) and kubeOidcProxy.https (8443)

### Phase 3+: New Helm Charts (9)
- [ ] `helm/tailscale/` - Tailscale operator (Phase 3)
- [ ] `helm/cloudflared/` - Cloudflare Tunnel (Phase 4)
- [ ] `helm/crossplane/` - Crossplane core (Phase 5)
- [ ] `helm/crossplane-aws/` - AWS providers + compositions (Phase 6)
- [ ] `helm/eks-cluster/` - EKS claim (Phase 6)
- [ ] `helm/karpenter/` - Karpenter (Phase 6)
- [ ] `helm/keda/` - KEDA (Phase 6)
- [ ] `helm/backstage/` - Developer portal (Phase 7)
- [ ] `helm/aks-cluster/` - AKS claim (Phase 8)

### Existing Charts to Modify (multi-cluster support)
- [ ] `helm/cilium/` - Add values-eks.yaml, values-aks.yaml (CNI chaining mode)
- [ ] `helm/tetragon/` - Add values-eks.yaml, values-aks.yaml
- [ ] `helm/kyverno/` - Add values-eks.yaml, values-aks.yaml
- [ ] `helm/monitoring/` - Add values-alloy-spoke.yaml (works for both clouds)
- [ ] `helm/vault-secrets-operator/` - Add values-eks.yaml, values-aks.yaml
- [ ] `helm/cloudflared/` - Add values-eks.yaml, values-aks.yaml (separate tunnels per cloud)
- [ ] `helm/argo-rollouts/` - Add values-eks.yaml, values-aks.yaml
- [ ] `helm/karpenter/` - Add values-aks.yaml (AKSNodeClass)

### ArgoCD Applications
- [x] `helm/argocd/templates/applications/headlamp.yaml` (Wave 5, Phase 2) ✅
- [x] `helm/argocd/templates/applications/kube-oidc-proxy.yaml` (Wave 5, Phase 2) ✅
- [ ] `helm/argocd/templates/applications/tailscale.yaml` (Wave 1, Phase 3)
- [ ] `helm/argocd/templates/applications/cloudflared.yaml` (Wave 1, Phase 4)
- [ ] `helm/argocd/templates/applications/crossplane.yaml` (Wave 1, Phase 5)
- [ ] `helm/argocd/templates/applications/crossplane-aws.yaml` (Wave 2, Phase 6)
- [ ] `helm/argocd/templates/applications/eks-cluster.yaml` (Wave 2, Phase 6)
- [ ] `helm/argocd/templates/applications/spoke-agents.yaml` (ApplicationSet, Phase 6)
- [ ] `helm/argocd/templates/applications/backstage.yaml` (Wave 5, Phase 7)
- [ ] `helm/argocd/templates/applications/aks-cluster.yaml` (Wave 2, Phase 8)

### Ports to Add (helm/ports.yaml)
- [x] headlamp (Phase 2) ✅
- [x] kubeOidcProxy (Phase 2) ✅
- [ ] tailscale (Phase 3)
- [ ] cloudflared (Phase 4)
- [ ] crossplane (Phase 5)
- [ ] karpenter (Phase 6)
- [ ] keda (Phase 6)
- [ ] backstage (Phase 7)

```yaml
ports:
  headlamp:        # ✅ Complete
    http: 4466
  kubeOidcProxy:   # ✅ Complete
    https: 8443
  tailscale:
    metrics: 9001
  cloudflared:
    metrics: 9090
  crossplane:
    metrics: 8080
    webhooks: 9443
  karpenter:
    metrics: 8080
    healthProbe: 8081
    webhooks: 8443
  keda:
    metrics: 8080
    metricsService: 9666
    webhooks: 9443
  backstage:
    http: 7007
```

---

## Decisions Made

- **Cloud Credentials:** Vault secrets engines (AWS + Azure, dynamic, auto-rotating)
- **Cluster Provisioning:** Reusable XRD + Composition pattern (works for EKS and AKS)
- **External Ingress:** Cloudflare Tunnel (replaces ALB/Azure LB - zero cost, zero-trust)
- **Cloudflare Tunnels:** Three separate tunnels (KinD + EKS + AKS) for independent ingress
- **SSO:** Keycloak for all UIs (Headlamp, Backstage, Grafana, ArgoCD, etc.)
- **Cross-cluster networking:** Tailscale (not Cluster Mesh - see rationale below)
- **Node Autoscaling:** Karpenter on EKS, NAP (Karpenter-based) on AKS

## Architectural Decisions (for CV/interviews)

**Why Tailscale instead of Cilium Cluster Mesh?**
> Cluster Mesh requires Cilium as the primary CNI. On EKS/AKS, we use Cilium in CNI chaining mode with cloud-native CNI (AWS VPC CNI / Azure CNI) to support Karpenter/NAP dynamic node provisioning. This constraint makes Cluster Mesh impractical. Tailscale provides equivalent cross-cluster connectivity without this limitation.

**Why multi-cloud (EKS + AKS)?**
> Demonstrates cloud-agnostic architecture using Crossplane, Tailscale, and Cloudflare Tunnel. Same patterns, different cloud primitives. Shows understanding of vendor-neutral infrastructure.

---

## Vault AWS Secrets Engine Setup

Configure Vault to provide dynamic AWS credentials for Crossplane:

```bash
# Enable AWS secrets engine
vault secrets enable aws

# Configure root credentials (used to generate dynamic creds)
vault write aws/config/root \
  access_key=$AWS_ACCESS_KEY_ID \
  secret_key=$AWS_SECRET_ACCESS_KEY \
  region=eu-west-1

# Create role for Crossplane with required permissions
vault write aws/roles/crossplane-role \
  credential_type=iam_user \
  policy_arns=arn:aws:iam::aws:policy/AdministratorAccess \
  default_ttl=1h \
  max_ttl=24h
```

**VaultStaticSecret for Crossplane (helm/crossplane-aws/templates/vault-secret.yaml):**
```yaml
apiVersion: secrets.hashicorp.com/v1beta1
kind: VaultStaticSecret
metadata:
  name: aws-credentials
  namespace: crossplane-system
spec:
  type: kv-v2
  mount: aws
  path: creds/crossplane-role
  destination:
    name: aws-credentials
    create: true
    transformation:
      excludeRaw: true
      templates:
        credentials:
          text: |
            [default]
            aws_access_key_id = {{ .Secrets.access_key }}
            aws_secret_access_key = {{ .Secrets.secret_key }}
  refreshAfter: 30m
  vaultAuthRef: vault-auth
```

---

## Prerequisites Checklist

Before starting implementation:

- [ ] Tailscale account created
- [ ] Tailscale OAuth client ID and secret
- [ ] Cloudflare account (free tier works)
- [ ] Domain added to Cloudflare (for Tunnel hostnames)
- [ ] Cloudflare Tunnel created (`cloudflared tunnel create <name>`)
- [ ] AWS account with appropriate permissions
- [ ] Vault AWS secrets engine configured
- [ ] EKS region chosen (e.g., eu-west-1)
- [ ] AKS region chosen (e.g., westeurope)
- [ ] Pod CIDR ranges documented (KinD, EKS, AKS)
- [ ] Azure credentials (subscription ID, tenant ID, client ID/secret)
- [ ] Vault Azure secrets engine configured
- [x] Keycloak OIDC client created for headlamp (using VaultStaticSecret from Transit Vault)
- [ ] Keycloak OIDC client created for backstage with secrets as SealedSecrets
- [ ] Third Cloudflare Tunnel created for AKS
