# Terraform + Terragrunt

Infrastructure as Code for provisioning and managing cloud resources.

## Why Terraform + Terragrunt

Terraform provides a declarative, provider-agnostic way to define infrastructure. Terragrunt adds DRY configuration, dependency orchestration, and remote state management on top. Chosen over Pulumi/CDK for its maturity, ecosystem, and HCL's readability for infrastructure definitions.

## Role in This Project

- **HCP Terraform**: Remote state storage and locking via HashiCorp Cloud Platform
- **Module Structure**: Reusable modules in `terraform/modules/`, live configs in `terraform/live/`
- **Dependency Chain**: Terragrunt orchestrates deploy order (VPC → Cluster → Bootstrap → ArgoCD)
- **Bootstrap Phase**: Everything before ArgoCD — cluster creation, CNI, CRDs, secrets infrastructure
- **Multi-Target**: Same modules support KinD (local) and EKS (AWS)

After Terraform bootstraps the cluster and ArgoCD, [ArgoCD](argocd.md) takes over for application lifecycle management.

## Related

- [ArgoCD](argocd.md) — Takes over after Terraform bootstrap
- [Crossplane](crossplane.md) — Alternative IaC approach, running inside Kubernetes
- [Infrastructure as Code](../concepts/infrastructure-as-code.md) — Terraform is the primary IaC tool

## Docs

- [Terraform Documentation](https://developer.hashicorp.com/terraform/docs)
- [Terragrunt Documentation](https://terragrunt.gruntwork.io/docs/)
- [HCP Terraform](https://developer.hashicorp.com/terraform/cloud-docs)
