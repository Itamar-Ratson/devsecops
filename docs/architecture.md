# Architecture Overview

This project is a DevSecOps reference implementation built on Kubernetes, demonstrating zero-trust security, GitOps workflows, and full-stack observability.

## Infrastructure Targets

| Target | Purpose | Technology |
|--------|---------|------------|
| KinD | Local development & CI | Docker-in-Docker K8s |
| EKS | AWS production | Managed Kubernetes |

## Component Map

### Networking & Ingress

| Tool | Purpose | Docs |
|------|---------|------|
| [Cilium](tools/cilium.md) | eBPF-based CNI, network policies, load balancing | [cilium.io](https://docs.cilium.io) |
| [Gateway API](tools/gateway-api.md) | L4/L7 routing (Kubernetes-native ingress) | [gateway-api.sigs.k8s.io](https://gateway-api.sigs.k8s.io) |
| [Cloudflare Tunnel](tools/cloudflare.md) | Secure external ingress without open ports | [developers.cloudflare.com](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/) |
| [Tailscale](tools/tailscale.md) | Mesh networking for cross-cluster connectivity | [tailscale.com/kb](https://tailscale.com/kb/) |

### Security & Policy

| Tool | Purpose | Docs |
|------|---------|------|
| [Tetragon](tools/tetragon.md) | eBPF runtime security and process observability | [tetragon.io](https://tetragon.io/docs/) |
| [Kyverno](tools/kyverno.md) | Kubernetes-native policy engine | [kyverno.io](https://kyverno.io/docs/) |
| [Trivy](tools/trivy.md) | Container vulnerability and misconfiguration scanning | [aquasecurity.github.io/trivy](https://aquasecurity.github.io/trivy/) |

### Secrets & Certificates

| Tool | Purpose | Docs |
|------|---------|------|
| [Vault](tools/vault.md) | Secrets management and transit encryption | [developer.hashicorp.com/vault](https://developer.hashicorp.com/vault/docs) |
| [Sealed Secrets](tools/sealed-secrets.md) | Encrypt K8s Secrets for safe Git storage | [github.com/bitnami-labs/sealed-secrets](https://github.com/bitnami-labs/sealed-secrets) |
| [cert-manager](tools/cert-manager.md) | Automated certificate lifecycle management | [cert-manager.io](https://cert-manager.io/docs/) |

### Identity & Auth

| Tool | Purpose | Docs |
|------|---------|------|
| [Keycloak](tools/keycloak.md) | OpenID Connect identity provider | [keycloak.org](https://www.keycloak.org/documentation) |

### Observability

| Tool | Purpose | Docs |
|------|---------|------|
| [Prometheus + Grafana Stack](tools/prometheus-stack.md) | Metrics, logs, traces, and dashboards | [prometheus.io](https://prometheus.io/docs/) |
| [OpenTelemetry](tools/opentelemetry.md) | Vendor-neutral telemetry collection | [opentelemetry.io](https://opentelemetry.io/docs/) |
| [Headlamp](tools/headlamp.md) | Kubernetes dashboard with OIDC SSO | [headlamp.dev](https://headlamp.dev/docs/latest/) |

### GitOps & Deployment

| Tool | Purpose | Docs |
|------|---------|------|
| [ArgoCD](tools/argocd.md) | GitOps continuous delivery | [argo-cd.readthedocs.io](https://argo-cd.readthedocs.io/) |
| [Argo Rollouts](tools/argo-rollouts.md) | Progressive delivery (canary, blue-green) | [argoproj.github.io/argo-rollouts](https://argoproj.github.io/argo-rollouts/) |
| [Terraform + Terragrunt](tools/terraform.md) | Infrastructure as Code | [developer.hashicorp.com/terraform](https://developer.hashicorp.com/terraform/docs) |

### Infrastructure on K8s

| Tool | Purpose | Docs |
|------|---------|------|
| [Crossplane](tools/crossplane.md) | Provision cloud resources from Kubernetes | [docs.crossplane.io](https://docs.crossplane.io/) |
| [Strimzi](tools/strimzi.md) | Kubernetes-native Kafka operator | [strimzi.io](https://strimzi.io/documentation/) |

### Container Registry

| Tool | Purpose | Docs |
|------|---------|------|
| [Zot](tools/zot.md) | OCI-compliant registry with pull-through caching | [zotregistry.dev](https://zotregistry.dev/docs/) |

### CI/CD

| Tool | Purpose | Docs |
|------|---------|------|
| [GitHub Actions](tools/github-actions.md) | CI/CD pipelines with security scanning | [docs.github.com/actions](https://docs.github.com/en/actions) |

## Concepts

These documents explain the principles behind the architecture and how they're implemented:

### Culture & Practice
- [DevOps](concepts/devops.md) — Breaking down silos between development and operations
- [DevSecOps](concepts/devsecops.md) — Security as a first-class citizen in the DevOps lifecycle
- [Cloud Native](concepts/cloud-native.md) — Building systems designed for Kubernetes and cloud environments

### Delivery & Automation
- [CI/CD](concepts/ci-cd.md) — Automated pipelines that build, test, scan, and deliver every change
- [GitOps](concepts/gitops.md) — Declarative, Git-driven infrastructure and application delivery
- [Infrastructure as Code](concepts/infrastructure-as-code.md) — All infrastructure defined in version-controlled code

### Security
- [Zero Trust](concepts/zero-trust.md) — Default-deny networking and identity-based access
- [Least Privilege](concepts/least-privilege.md) — Minimum permissions at every layer
- [Shift-Left Security](concepts/shift-left.md) — Security testing early and continuously in the pipeline
- [Defense in Depth](concepts/defense-in-depth.md) — Multiple independent security layers
- [Supply Chain Security](concepts/supply-chain-security.md) — Securing artifacts from source to runtime
- [Policy as Code](concepts/policy-as-code.md) — Machine-enforceable security and compliance rules
- [Secrets Management](concepts/secrets-management.md) — Secure lifecycle for credentials and sensitive data

### Technology
- [eBPF](concepts/ebpf.md) — Programmable kernel technology powering Cilium and Tetragon
- [Observability](concepts/observability.md) — Metrics, logs, and traces for full system visibility
- [Multi-Cluster Networking](concepts/multi-cluster.md) — Cross-cluster connectivity and service discovery

## Deploy Order

```
HCP Workspaces → Transit Vault → Registry Cache → KinD Cluster
    → Cluster Bootstrap (Cilium, CRDs, Sealed Secrets)
        → Vault Config → ArgoCD → All Applications (via sync waves)
```

Terraform/Terragrunt handles the bootstrap. ArgoCD takes over for everything else via sync waves, following the [GitOps](concepts/gitops.md) model.
