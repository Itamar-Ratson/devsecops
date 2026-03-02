# Continuous Integration / Continuous Delivery

Automated pipelines that build, test, scan, and deliver every code change.

## What Is CI/CD

**Continuous Integration (CI)** — Every code change is automatically built, tested, and validated. Developers merge frequently; broken builds are fixed immediately.

**Continuous Delivery (CD)** — Every validated change is automatically deployable to production. The decision to deploy may be manual, but the process is fully automated.

**Continuous Deployment** — Every validated change is automatically deployed to production with no manual step.

## How This Project Implements CI/CD

### CI Pipeline (GitHub Actions)

Triggered on every PR and push to main:

```
Commit → Gitleaks → Trivy scan → Cosign sign → Syft SBOM
    → Helm lint → Terraform plan → All pass ✓
```

Each step is a quality or security gate. If any step fails, the pipeline stops and the PR can't merge.

### CD via GitOps

This project uses [GitOps](gitops.md) for continuous delivery instead of traditional CD pipelines:

```
Merge to main → ArgoCD detects change → Sync to cluster → Healthy ✓
```

ArgoCD replaces the "deploy" stage of a traditional pipeline. There's no `kubectl apply` or `helm install` in CI — ArgoCD handles delivery by reconciling Git state with cluster state.

### Integration Testing (DAST)

A scheduled workflow deploys the full stack to a KinD cluster and runs OWASP ZAP security scans against it:

```
Terragrunt apply → Full stack deploy → ArgoCD healthy
    → OWASP ZAP DAST → Verify → Terragrunt destroy
```

This catches issues that unit tests and static analysis can't — actual runtime vulnerabilities in the deployed system.

### The Separation

| Concern | Handled By |
|---------|-----------|
| Build, test, scan | GitHub Actions (CI) |
| Deploy, reconcile | ArgoCD (CD via GitOps) |
| Integration test | GitHub Actions + KinD (scheduled) |

CI and CD are intentionally decoupled. CI validates. ArgoCD delivers. Neither depends on the other's implementation.

## Related Concepts

- [DevOps](devops.md) — CI/CD is a core DevOps practice
- [GitOps](gitops.md) — The CD model used in this project
- [Shift-Left Security](shift-left.md) — Security checks embedded in CI
- [Supply Chain Security](supply-chain-security.md) — Image signing and SBOMs in CI

## Tools

- [GitHub Actions](../tools/github-actions.md) — CI pipeline
- [ArgoCD](../tools/argocd.md) — CD via GitOps

## Further Reading

- [Continuous Delivery (Martin Fowler)](https://martinfowler.com/bliki/ContinuousDelivery.html)
- [DORA Metrics](https://dora.dev/) — Measuring CI/CD effectiveness
