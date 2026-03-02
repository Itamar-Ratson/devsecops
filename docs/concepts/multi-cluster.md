# Multi-Cluster Networking

Cross-cluster connectivity and service discovery across environments.

## What Is Multi-Cluster Networking

Multi-cluster networking connects multiple Kubernetes clusters so that pods in one cluster can communicate with pods in another — as if they were in the same network. This enables workload distribution across regions, cloud providers, or environments (dev/prod).

## How This Project Implements Multi-Cluster

### Architecture

```
KinD (local) ←──Tailscale mesh──→ EKS (AWS)
     ↕                                  ↕
  Cilium CNI                        Cilium CNI
     ↕                                  ↕
  ClusterMesh ←──── etcd sync ────→ ClusterMesh
```

### Three Layers

| Layer | Tool | Role |
|-------|------|------|
| **Network underlay** | Tailscale | Encrypted WireGuard mesh between clusters |
| **Cluster connectivity** | Cilium ClusterMesh | Pod-to-pod routing and shared service discovery |
| **External ingress** | Cloudflare Tunnel | Public access without open ports |

### Tailscale (Network Layer)

Tailscale creates an encrypted WireGuard mesh between the KinD and EKS clusters. The Tailscale Operator runs in each cluster and manages subnet routes, exposing pod CIDRs across the mesh.

### Cilium ClusterMesh (Service Layer)

ClusterMesh connects Cilium instances across clusters. Each cluster's etcd (managed by clustermesh-apiserver) syncs endpoint information. The result: pods can reach services in other clusters by name, and CiliumNetworkPolicies can reference remote cluster identities.

An internal NLB provides a stable endpoint for ClusterMesh API traffic.

### Cloudflare Tunnel (External Layer)

Cloudflare Tunnel provides external access without opening inbound ports on either cluster. Each cluster runs its own tunnel, and Cloudflare routes external traffic to the appropriate cluster.

## Tools

- [Cilium](../tools/cilium.md) — ClusterMesh for cross-cluster pod networking
- [Tailscale](../tools/tailscale.md) — WireGuard mesh underlay
- [Cloudflare](../tools/cloudflare.md) — External ingress layer
- [Gateway API](../tools/gateway-api.md) — L7 routing within and across clusters

## Further Reading

- [Cilium ClusterMesh](https://docs.cilium.io/en/stable/network/clustermesh/)
- [Tailscale Kubernetes Operator](https://tailscale.com/kb/1236/kubernetes-operator/)
