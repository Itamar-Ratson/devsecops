# Defense in Depth

Multiple independent security layers — no single point of failure.

## What Is Defense in Depth

Defense in depth is a security strategy that layers multiple independent controls so that if one fails, the next one catches the threat. It assumes any single control can be bypassed and designs accordingly. Originating from military strategy, it's the principle that a castle has walls, a moat, guards, and locked doors — not just one.

## How This Project Implements Defense in Depth

### The Layers

```
Internet
  │
  ├─ [1] Cloudflare Access ─── Identity verification at the edge
  │
  ├─ [2] Cloudflare Tunnel ─── No open inbound ports
  │
  ├─ [3] Gateway API + TLS ─── Encrypted routing, cert-manager certificates
  │
  ├─ [4] CiliumNetworkPolicy ─ Default-deny L3/L4/L7, explicit allows only
  │
  ├─ [5] Kyverno ───────────── Admission control, blocks unsafe pod specs
  │
  ├─ [6] Vault ─────────────── Identity-based secrets, no static credentials
  │
  ├─ [7] Tetragon ──────────── Runtime process/syscall monitoring and blocking
  │
  └─ [8] Trivy Operator ────── Continuous vulnerability scanning of running workloads
```

### Each Layer Is Independent

| Layer | What It Stops | If It Fails... |
|-------|--------------|-----------------|
| Cloudflare Access | Unauthenticated users | Gateway API still requires valid TLS |
| Network Policy | Unauthorized pod-to-pod traffic | Kyverno prevents escalation-capable pods |
| Kyverno | Privileged containers, bad configs | Tetragon blocks suspicious runtime behavior |
| Vault auth | Unauthorized secret access | Secrets aren't in env vars or config maps |
| Tetragon | Malicious process execution | Network policies limit blast radius |

No single compromise gives an attacker full access. Each layer reduces the blast radius independently.

### Pre-Production Layers

Defense in depth extends to the pipeline too:

```
[Gitleaks] → [Trivy scan] → [Cosign sign] → [Kyverno admit] → [Runtime monitoring]
```

A vulnerability must evade secret detection, image scanning, admission control, AND runtime monitoring to have impact.

## Related Concepts

- [Zero Trust](zero-trust.md) — The networking model within defense in depth
- [Least Privilege](least-privilege.md) — Minimum permissions at each layer limits blast radius
- [DevSecOps](devsecops.md) — Embedding security at every stage
- [Shift-Left Security](shift-left.md) — Pre-production defense layers

## Tools

- [Cloudflare](../tools/cloudflare.md) — Edge identity verification and tunnels (layers 1-2)
- [Gateway API](../tools/gateway-api.md) — Encrypted routing with TLS (layer 3)
- [cert-manager](../tools/cert-manager.md) — Certificate management for TLS (layer 3)
- [Cilium](../tools/cilium.md) — CiliumNetworkPolicy default-deny enforcement (layer 4)
- [Kyverno](../tools/kyverno.md) — Admission control for pod security (layer 5)
- [Vault](../tools/vault.md) — Identity-based secrets access (layer 6)
- [Tetragon](../tools/tetragon.md) — Runtime process and syscall monitoring (layer 7)
- [Trivy](../tools/trivy.md) — Continuous vulnerability scanning (layer 8)

## Further Reading

- [NIST Defense in Depth (SP 800-53)](https://csrc.nist.gov/publications/detail/sp/800-53/rev-5/final)
- [OWASP Defense in Depth](https://cheatsheetseries.owasp.org/cheatsheets/Attack_Surface_Analysis_Cheat_Sheet.html)
