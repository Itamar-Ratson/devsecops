# Infrastructure as Code

Define all infrastructure in version-controlled, declarative code — no manual provisioning.

## What Is Infrastructure as Code

Infrastructure as Code (IaC) replaces manual configuration (clicking in consoles, running ad-hoc commands) with code that describes the desired state of infrastructure. This code is versioned, reviewed, tested, and applied automatically — the same workflow as application code.

**Core principles:**
1. **Declarative** — Describe *what* you want, not *how* to get there
2. **Idempotent** — Applying the same code twice produces the same result
3. **Version Controlled** — All changes tracked in Git with full audit trail
4. **Reviewable** — Infrastructure changes go through pull requests

## How This Project Implements IaC

### Two Layers

| Layer | Tool | Scope |
|-------|------|-------|
| **Cluster infrastructure** | Terraform + Terragrunt | VPC, EKS/KinD cluster, Vault, IAM, DNS |
| **Application infrastructure** | Helm + ArgoCD | K8s workloads, configs, policies |
| **Cloud resources (in-cluster)** | Crossplane | S3 buckets, cloud resources via K8s CRDs |

### Terraform + Terragrunt

- **Modules**: Reusable components in `terraform/modules/` (VPC, EKS, Vault, etc.)
- **Live Configs**: Environment-specific values in `terraform/live/`
- **Terragrunt**: Orchestrates module dependencies, manages remote state, enforces DRY
- **HCP Terraform**: Remote state storage and locking

### Helm Charts

- All Kubernetes workloads defined as Helm charts in `helm/`
- Values files declare configuration; templates produce K8s manifests
- ArgoCD renders and applies charts — no manual `helm install`

### Crossplane

- Cloud resources (S3 buckets) defined as Kubernetes CRDs
- Managed by ArgoCD like any other K8s resource
- Demonstrates infrastructure management *inside* the Kubernetes control plane

### No Manual Steps

The project enforces strict rules:
- Never `kubectl create/patch/edit` — only declarative apply
- Never `helm install` for ArgoCD-managed charts — commit and sync
- Infrastructure changes go through Git → CI validation → merge → automated apply

## Tools

- [Terraform + Terragrunt](../tools/terraform.md) — Primary IaC for cluster infrastructure
- [Crossplane](../tools/crossplane.md) — Kubernetes-native IaC
- [ArgoCD](../tools/argocd.md) — Applies Helm charts declaratively
- [GitOps](gitops.md) — The delivery model for IaC

## Further Reading

- [Terraform Documentation](https://developer.hashicorp.com/terraform/docs)
- [Terragrunt Documentation](https://terragrunt.gruntwork.io/docs/)
- [Crossplane Concepts](https://docs.crossplane.io/latest/concepts/)
