# DevSecOps

Security as a first-class citizen in the DevOps lifecycle — not an afterthought.

## What Is DevSecOps

DevSecOps integrates security practices into every phase of the software delivery lifecycle. Traditional security is a gate at the end ("we'll review it before release"). DevSecOps makes security everyone's responsibility, automated and continuous — the same way DevOps did for operations.

**Key difference from DevOps:**
- **DevOps**: Dev + Ops collaboration, automated delivery
- **DevSecOps**: Dev + Sec + Ops — security embedded in every stage, not bolted on

## How This Project Implements DevSecOps

### Security at Every Stage

| Stage | Practice | Tools |
|-------|----------|-------|
| **Code** | Secret detection | Gitleaks |
| **Build** | Image scanning, SBOM, signing | Trivy, Syft, Cosign |
| **Deploy** | Admission control, policy enforcement | Kyverno |
| **Runtime** | Network zero-trust, process monitoring | Cilium, Tetragon |
| **Test** | Dynamic security testing | OWASP ZAP |
| **Secrets** | Centralized, audited, rotatable | Vault, Sealed Secrets |
| **Access** | Identity-based, least privilege | Keycloak, RBAC |

### Security as Code

Every security control is defined in code and version-controlled:

- **Network policies** → CiliumNetworkPolicy YAML in Helm charts
- **Admission policies** → Kyverno ClusterPolicy YAML
- **Access policies** → Vault policies in Terraform HCL
- **RBAC** → Kubernetes Role/ClusterRole in Helm templates

This means security changes go through the same review process as application changes — PRs, CI validation, audit trail.

### Automated Security Gates

The CI pipeline enforces security checks automatically. A PR can't merge if:
- Gitleaks detects secrets in the diff
- Trivy finds critical CVEs in container images
- Helm charts fail validation

No manual security review required for standard changes — the automation catches the common issues.

### Defense in Depth

Security isn't a single tool or layer. This project stacks multiple independent controls:

```
[Cloudflare Access] → [Gateway API + TLS] → [CiliumNetworkPolicy]
    → [Kyverno admission] → [Vault secrets] → [Tetragon runtime]
```

A failure in any one layer is caught by the next.

## Related Concepts

- [DevOps](devops.md) — The foundation DevSecOps builds on
- [Shift-Left Security](shift-left.md) — Moving security checks earlier
- [Zero Trust](zero-trust.md) — Network and identity security model
- [Supply Chain Security](supply-chain-security.md) — Securing the build pipeline
- [Defense in Depth](defense-in-depth.md) — Layered security strategy
- [Policy as Code](policy-as-code.md) — Codified security controls

## Tools

- [Trivy](../tools/trivy.md) — Image scanning and SBOM generation
- [Cilium](../tools/cilium.md) — Network zero-trust enforcement
- [Tetragon](../tools/tetragon.md) — Runtime process monitoring
- [Kyverno](../tools/kyverno.md) — Admission control and policy enforcement
- [Vault](../tools/vault.md) — Centralized secrets management
- [Sealed Secrets](../tools/sealed-secrets.md) — Git-safe encrypted secrets
- [Keycloak](../tools/keycloak.md) — Identity-based access control
- [Cloudflare](../tools/cloudflare.md) — Edge authentication and tunnels
- [GitHub Actions](../tools/github-actions.md) — CI pipeline with security gates

## Further Reading

- [OWASP DevSecOps Guideline](https://owasp.org/www-project-devsecops-guideline/)
- [NIST Secure Software Development Framework](https://csrc.nist.gov/projects/ssdf)
- [DoD DevSecOps Reference Design](https://dodcio.defense.gov/Portals/0/Documents/Library/DevSecOpsReferenceDesign.pdf)
