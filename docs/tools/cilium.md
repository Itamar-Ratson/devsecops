# Cilium

eBPF-based networking, security, and observability for Kubernetes.

## Why Cilium

Cilium replaces kube-proxy and traditional CNI plugins with eBPF programs running directly in the Linux kernel. This provides network policy enforcement at L3/L4/L7 without sidecar proxies, with significantly better performance than iptables-based alternatives (Calico, Flannel).

Chosen over Calico because Cilium provides a unified platform for CNI, network policies, load balancing, and observability — reducing the number of moving parts.

## Role in This Project

- **CNI**: All pod networking and service load balancing
- **Network Policies**: [CiliumNetworkPolicy](../concepts/zero-trust.md) for default-deny + explicit allow (L3/L4/L7)
- **Gateway API**: Native implementation of Kubernetes Gateway API for ingress routing
- **Hubble**: Network observability — flow logs, service maps, DNS visibility
- **ClusterMesh**: [Cross-cluster connectivity](../concepts/multi-cluster.md) between KinD and EKS

## Related

- [Tetragon](tetragon.md) — eBPF runtime security (same Cilium ecosystem)
- [Gateway API](gateway-api.md) — Cilium implements the Gateway API spec
- [eBPF](../concepts/ebpf.md) — The kernel technology powering Cilium
- [Zero Trust](../concepts/zero-trust.md) — Cilium enforces network-level zero trust
- [Least Privilege](../concepts/least-privilege.md) — Default-deny with explicit allows
- [Policy as Code](../concepts/policy-as-code.md) — CiliumNetworkPolicy as declarative security rules

## Docs

- [Cilium Documentation](https://docs.cilium.io)
- [Hubble Documentation](https://docs.cilium.io/en/stable/observability/hubble/)
- [ClusterMesh](https://docs.cilium.io/en/stable/network/clustermesh/)
