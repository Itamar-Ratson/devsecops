# Tailscale

WireGuard-based mesh networking for secure cross-cluster and remote connectivity.

## Why Tailscale

Tailscale builds a mesh VPN using WireGuard, providing encrypted point-to-point connections without a central gateway. Chosen for its simplicity in connecting KinD (local) with EKS (AWS) clusters and enabling MagicDNS for service discovery across environments.

## Role in This Project

- **Cross-Cluster Connectivity**: Connects KinD and EKS clusters over Tailscale's mesh network
- **Tailscale Operator**: Runs in-cluster to expose services and manage subnet routes
- **Key Rotation**: Automated auth key rotation via GitHub Actions workflow
- **Complement to ClusterMesh**: Provides the network underlay for [Cilium ClusterMesh](../concepts/multi-cluster.md)

## Related

- [Cilium](cilium.md) — ClusterMesh runs over Tailscale connectivity
- [Cloudflare](cloudflare.md) — External ingress (Tailscale handles private mesh)
- [Multi-Cluster Networking](../concepts/multi-cluster.md) — Tailscale enables the cross-cluster layer

## Docs

- [Tailscale Documentation](https://tailscale.com/kb/)
- [Tailscale Kubernetes Operator](https://tailscale.com/kb/1236/kubernetes-operator/)
