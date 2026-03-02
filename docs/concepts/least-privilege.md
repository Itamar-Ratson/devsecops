# Least Privilege

Grant the minimum permissions required — nothing more, nothing less.

## What Is Least Privilege

The principle of least privilege (PoLP) states that every identity — user, service, pod, process — should have only the permissions strictly necessary to perform its function. No default admin access, no "just in case" permissions, no shared credentials with broad scope.

**Why it matters:**
- **Limits blast radius** — A compromised service can only access what it was explicitly allowed
- **Reduces attack surface** — Fewer permissions means fewer things an attacker can exploit
- **Enables auditability** — Fine-grained permissions make it clear who accessed what and why
- **Supports compliance** — Most security frameworks (SOC 2, ISO 27001, NIST) require it

## How This Project Implements Least Privilege

### Network Level (Cilium)

Every namespace starts with **default-deny** for both ingress and egress. Each service explicitly declares only the endpoints and ports it needs:

```yaml
# Grafana can only reach Prometheus on port 9090 — nothing else
spec:
  endpointSelector:
    matchLabels:
      app: grafana
  egress:
    - toEndpoints:
        - matchLabels:
            app: prometheus
      toPorts:
        - ports:
            - port: "9090"
              protocol: TCP
```

A pod that doesn't declare egress to the internet simply can't reach it.

### Secrets Access (Vault)

Vault policies scope secret access per identity. Grafana's ServiceAccount can read `secret/data/grafana/*` — it cannot read Keycloak's secrets, and it cannot write anything:

```hcl
path "secret/data/grafana/*" {
  capabilities = ["read"]
}
```

Pods authenticate using their Kubernetes ServiceAccount JWT — no shared static tokens.

### Kubernetes RBAC

Roles are scoped to the narrowest possible level:
- **Namespace-scoped Roles** over ClusterRoles where possible
- **Specific verbs** (`get`, `list`, `watch`) instead of wildcard `*`
- **Specific resources** instead of broad API group access
- **ServiceAccount per workload** — no sharing the `default` SA across services

### Pod Security (Kyverno)

Kyverno enforces the restricted Pod Security Standard:
- No privileged containers
- No host networking, PID, or IPC namespaces
- Read-only root filesystem where possible
- `automountServiceAccountToken: false` on workloads that don't need API access
- Drop all capabilities, add back only what's needed

### IAM (AWS)

Terraform provisions IAM roles with minimal policies:
- OIDC federation — pods assume roles via ServiceAccount, no long-lived AWS credentials
- Scoped to specific resources (not `Resource: "*"`)
- Separate roles per workload, not a shared cluster role

### Cloudflare Access

Access policies restrict who can reach each service based on identity (email, IdP group), not just network location. Each application has its own access policy.

## Related Concepts

- [Zero Trust](zero-trust.md) — Least privilege is a core zero-trust principle
- [Defense in Depth](defense-in-depth.md) — Least privilege at each layer limits blast radius
- [Policy as Code](policy-as-code.md) — Policies enforce least privilege automatically
- [Secrets Management](secrets-management.md) — Scoped secret access per identity
- [DevSecOps](devsecops.md) — Least privilege applied throughout the lifecycle

## Tools

- [Cilium](../tools/cilium.md) — Default-deny network policies with explicit allows
- [Vault](../tools/vault.md) — Fine-grained secret access policies
- [Kyverno](../tools/kyverno.md) — Pod security and capability restrictions
- [Keycloak](../tools/keycloak.md) — Identity-based access scoping
- [Cloudflare](../tools/cloudflare.md) — Per-application access policies

## Further Reading

- [NIST Least Privilege (AC-6)](https://csrc.nist.gov/publications/detail/sp/800-53/rev-5/final)
- [Kubernetes RBAC](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)
- [Vault Policies](https://developer.hashicorp.com/vault/docs/concepts/policies)
