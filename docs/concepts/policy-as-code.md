# Policy as Code

Security and compliance rules defined in version-controlled, machine-enforceable code.

## What Is Policy as Code

Policy as Code replaces manual checklists, tribal knowledge, and ad-hoc reviews with machine-readable rules that are automatically enforced. Policies are treated like application code: versioned in Git, reviewed via PRs, tested in CI, and applied continuously.

**Benefits over manual policy:**
- **Consistent** — Applied the same way every time, no human error
- **Auditable** — Full Git history of who changed what and when
- **Testable** — Policies can be validated before deployment
- **Scalable** — Enforced across hundreds of workloads without manual review

## How This Project Implements Policy as Code

### Network Policies (Cilium)

CiliumNetworkPolicy CRDs define exactly what network traffic is allowed. Every namespace starts with default-deny; services declare their required connectivity explicitly.

```yaml
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: allow-grafana-to-prometheus
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

### Admission Policies (Kyverno)

Kyverno ClusterPolicy resources enforce standards at admission time — before resources are created:

- Block privileged containers
- Require resource limits
- Enforce image registry allowlists
- Validate label requirements

### Access Policies (Vault)

Vault policies define which identities can access which secrets, written in HCL and managed via Terraform:

```hcl
path "secret/data/grafana/*" {
  capabilities = ["read"]
}
```

### RBAC (Kubernetes)

Role and ClusterRole resources define API access, managed as Helm templates and deployed via ArgoCD.

### All Policies Live in Git

Every policy in this project is:
1. Defined as YAML/HCL in the repository
2. Reviewed through pull requests
3. Deployed through GitOps (ArgoCD) or Terraform
4. Never applied manually

## Related Concepts

- [Zero Trust](zero-trust.md) — Policies enforce the zero-trust model
- [Least Privilege](least-privilege.md) — Policies enforce minimum permissions
- [GitOps](gitops.md) — Policies deployed through Git like everything else
- [DevSecOps](devsecops.md) — Policy as code is a core DevSecOps practice
- [Infrastructure as Code](infrastructure-as-code.md) — Same principle applied to security rules

## Tools

- [Cilium](../tools/cilium.md) — Network policy enforcement
- [Kyverno](../tools/kyverno.md) — Admission policy engine
- [Vault](../tools/vault.md) — Access policies for secrets
- [Terraform](../tools/terraform.md) — Manages Vault and RBAC policies

## Further Reading

- [Kyverno Policy Library](https://kyverno.io/policies/)
- [Cilium Network Policy Editor](https://editor.networkpolicy.io/)
