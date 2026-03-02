# GitHub Actions

CI/CD pipelines for automated testing, security scanning, and deployment.

## Why GitHub Actions

Native CI/CD integration with GitHub — no external CI server needed. Provides matrix builds, reusable workflows, and a large marketplace of actions. Chosen for tight integration with the Git repository and simplicity.

## Role in This Project

Two main workflows:

### CI Pipeline (`ci.yaml`)
- **Gitleaks**: Secret detection in commits
- **Trivy**: Container image vulnerability scanning
- **Cosign**: Keyless container image signing (supply chain security)
- **Syft**: Software Composition Analysis (SBOM generation)
- **Helm Lint**: Chart validation
- **Terraform Plan**: Infrastructure change preview

### Deployment + DAST (`deployment-and-dast.yaml`)
- **Full Deploy**: Terragrunt bootstraps a KinD cluster with the entire stack
- **ArgoCD Sync**: Waits for all applications to become healthy
- **OWASP ZAP**: Dynamic Application Security Testing against deployed services
- **Teardown**: Destroys the cluster after testing

## Related

- [Trivy](trivy.md) — Image scanning in CI
- [Terraform](terraform.md) — Plan validation in CI
- [CI/CD](../concepts/ci-cd.md) — GitHub Actions is the CI engine
- [Supply Chain Security](../concepts/supply-chain-security.md) — Cosign signing and Syft SBOMs
- [Shift-Left Security](../concepts/shift-left.md) — CI is where shift-left happens
- [GitOps](../concepts/gitops.md) — CI validates; ArgoCD deploys

## Docs

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [OWASP ZAP](https://www.zaproxy.org/docs/)
- [Cosign](https://docs.sigstore.dev/cosign/overview/)
