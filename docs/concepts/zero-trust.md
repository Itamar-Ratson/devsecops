# Zero Trust

Never trust, always verify — default-deny networking and identity-based access.

## What Is Zero Trust

Zero Trust is a security model that assumes no implicit trust based on network location. Every request must be authenticated, authorized, and encrypted — whether it comes from inside or outside the network perimeter.

**Core principles:**
1. **Default Deny** — No traffic is allowed unless explicitly permitted
2. **Least Privilege** — Grant minimum permissions needed
3. **Verify Explicitly** — Authenticate and authorize every request
4. **Assume Breach** — Design as if the network is already compromised

## How This Project Implements Zero Trust

### Network Layer (L3/L4/L7)

Every namespace has CiliumNetworkPolicy with default-deny for both ingress and egress. Services must explicitly declare what they need to talk to. Policies use pod labels, not IP addresses.

```yaml
# Default deny all traffic
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
spec:
  endpointSelector: {}  # All pods
  ingress: []            # Deny all ingress
  egress: []             # Deny all egress
```

Then explicit allows are added per-service — only the ports and destinations each service actually needs.

### Identity Layer

- **Keycloak** provides centralized OIDC authentication
- **kube-oidc-proxy** bridges OIDC tokens to Kubernetes RBAC
- **Cloudflare Access** adds identity-aware authentication at the edge
- **Vault** uses Kubernetes ServiceAccount tokens for authentication — no static credentials

### Admission Control

- **Kyverno** enforces Pod Security Standards at admission time
- Blocks privileged containers, host networking, and unsafe configurations

### Runtime Enforcement

- **Tetragon** monitors and can block suspicious process execution, syscalls, and file access at the kernel level via eBPF

### Supply Chain

- **Cosign** signs container images (keyless, via Sigstore)
- **Trivy** scans for vulnerabilities before and after deployment

## Tools

- [Cilium](../tools/cilium.md) — Network policy enforcement
- [Keycloak](../tools/keycloak.md) — Identity provider
- [Kyverno](../tools/kyverno.md) — Admission control
- [Tetragon](../tools/tetragon.md) — Runtime security
- [Cloudflare](../tools/cloudflare.md) — Edge authentication
- [Vault](../tools/vault.md) — Identity-based secrets access

## Further Reading

- [NIST Zero Trust Architecture (SP 800-207)](https://csrc.nist.gov/publications/detail/sp/800-207/final)
- [Cilium Network Policies](https://docs.cilium.io/en/stable/security/policy/)
