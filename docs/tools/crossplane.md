# Crossplane

Provision and manage cloud infrastructure using Kubernetes APIs.

## Why Crossplane

Crossplane extends Kubernetes with CRDs that represent cloud resources (S3 buckets, RDS instances, etc.), allowing infrastructure to be managed with the same GitOps workflow as applications. Chosen to demonstrate an alternative to Terraform for cloud resource management that lives inside the Kubernetes control plane.

## Role in This Project

- **AWS Provider**: Manages AWS resources (S3 buckets) via Kubernetes CRDs
- **Compositions**: Reusable infrastructure templates combining multiple resources
- **GitOps Native**: Cloud resources are declared in Git and reconciled by ArgoCD, just like applications
- **Complement to Terraform**: Terraform handles cluster-level infrastructure; Crossplane handles application-level cloud resources

## Related

- [Terraform](terraform.md) — Cluster-level IaC (Crossplane handles app-level)
- [ArgoCD](argocd.md) — Reconciles Crossplane resources via GitOps
- [Infrastructure as Code](../concepts/infrastructure-as-code.md) — Crossplane is the Kubernetes-native IaC approach

## Docs

- [Crossplane Documentation](https://docs.crossplane.io/)
- [AWS Provider](https://marketplace.upbound.io/providers/upbound/provider-family-aws/)
