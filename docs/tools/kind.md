# KinD (Kubernetes in Docker)

Local Kubernetes clusters using Docker containers as nodes.

## Why KinD

KinD runs full Kubernetes clusters inside Docker containers, providing a lightweight, disposable environment for development and CI testing. Chosen over Minikube for its multi-node support, faster startup, and better CI compatibility (runs inside Docker-in-Docker without virtualization).

## Role in This Project

- **Local Development**: Full stack runs locally — same Helm charts and configs as production (EKS)
- **CI Testing**: GitHub Actions spins up a KinD cluster, deploys everything, runs DAST tests, then destroys it
- **Terraform Managed**: Cluster creation handled by a Terraform module (`terraform/modules/k8s/kind/`)
- **Multi-Node**: Configured with control plane + worker nodes for realistic scheduling
- **Cilium CNI**: KinD's default CNI is replaced with Cilium for network policy enforcement

## Related

- [Terraform](terraform.md) — Provisions the KinD cluster
- [Cilium](cilium.md) — Replaces KinD's default CNI
- [GitHub Actions](github-actions.md) — KinD clusters used for CI integration tests
- [Cloud Native](../concepts/cloud-native.md) — Same manifests deploy to KinD and EKS
- [CI/CD](../concepts/ci-cd.md) — KinD enables full-stack integration testing in CI

## Docs

- [KinD Documentation](https://kind.sigs.k8s.io/)
- [KinD Configuration](https://kind.sigs.k8s.io/docs/user/configuration/)
