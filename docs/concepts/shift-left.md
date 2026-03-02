# Shift-Left Security

Move security testing earlier in the development lifecycle — find and fix issues before they reach production.

## What Is Shift-Left

"Shift-left" means moving quality and security checks from the right side of the timeline (production) to the left (development and CI). The earlier a vulnerability is found, the cheaper it is to fix. Instead of security being a gate at the end, it's embedded throughout the pipeline.

## How This Project Implements Shift-Left

### Pre-Commit / Development

| Check | Tool | What It Catches |
|-------|------|-----------------|
| Secret detection | Gitleaks | API keys, passwords, tokens committed to code |

### Build / CI Pipeline

| Check | Tool | What It Catches |
|-------|------|-----------------|
| Image scanning | Trivy | Known CVEs in container images |
| SBOM generation | Syft | Software composition for supply chain visibility |
| Image signing | Cosign | Ensures image integrity and provenance |
| Helm linting | Helm | Chart misconfigurations |
| Terraform plan | Terraform | Infrastructure change preview |

### Deploy / Admission

| Check | Tool | What It Catches |
|-------|------|-----------------|
| Policy enforcement | Kyverno | Privileged containers, missing labels, bad configs |
| Pod Security Standards | Kyverno | Violations of restricted/baseline profiles |

### Runtime / Production

| Check | Tool | What It Catches |
|-------|------|-----------------|
| Continuous scanning | Trivy Operator | New CVEs in running workloads |
| Network enforcement | Cilium | Unauthorized network access |
| Process monitoring | Tetragon | Suspicious runtime behavior |
| DAST scanning | OWASP ZAP | Application-level vulnerabilities (XSS, SQLi, etc.) |

### The Full Pipeline

```
Code → [Gitleaks] → Build → [Trivy, Syft, Cosign] → Deploy → [Kyverno]
    → Runtime → [Tetragon, Cilium, Trivy Operator, ZAP]
```

Security is not a single gate — it's a series of checks at every stage, each catching different classes of issues.

## Tools

- [Gitleaks](../tools/gitleaks.md) — Secret detection at the code stage
- [Trivy](../tools/trivy.md) — Vulnerability scanning (CI + runtime)
- [Cosign](../tools/cosign.md) — Image signing at build time
- [Kyverno](../tools/kyverno.md) — Admission-time policy enforcement
- [Tetragon](../tools/tetragon.md) — Runtime security monitoring
- [GitHub Actions](../tools/github-actions.md) — CI pipeline executing security checks
- [Cilium](../tools/cilium.md) — Network-level enforcement

## Further Reading

- [OWASP DevSecOps Guideline](https://owasp.org/www-project-devsecops-guideline/)
- [Sigstore / Cosign](https://docs.sigstore.dev/)
