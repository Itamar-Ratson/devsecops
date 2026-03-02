# Gateway API

Kubernetes-native L4/L7 routing — the successor to Ingress.

## Why Gateway API

Gateway API is the official Kubernetes evolution of the Ingress resource, providing richer routing (HTTP header matching, traffic splitting, TLS passthrough) with a role-oriented model (platform admin vs application developer). Chosen over Ingress for its expressiveness and forward compatibility.

## Role in This Project

- **HTTP Routing**: HTTPRoute resources define application routing rules
- **TLS Termination**: Gateway resources handle TLS with cert-manager certificates
- **Cilium Implementation**: Cilium natively implements the Gateway API spec (no separate ingress controller needed)
- **Multi-Cluster**: Gateway resources work with ClusterMesh for cross-cluster routing

## Related

- [Cilium](cilium.md) — Implements the Gateway API spec
- [cert-manager](cert-manager.md) — Provides TLS certificates for Gateways
- [Cloudflare](cloudflare.md) — External ingress layer in front of Gateway API

## Docs

- [Gateway API Documentation](https://gateway-api.sigs.k8s.io/)
- [Cilium Gateway API](https://docs.cilium.io/en/stable/network/servicemesh/gateway-api/gateway-api/)
