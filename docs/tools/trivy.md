# Trivy

Comprehensive security scanner for containers, filesystems, and Kubernetes.

## Why Trivy

Trivy provides vulnerability scanning, misconfiguration detection, and SBOM generation in a single tool. Chosen over Snyk/Grype for its breadth of scanning targets and strong Kubernetes operator support.

## Role in This Project

- **CI Pipeline**: Scans container images during build for known CVEs
- **Trivy Operator**: Continuous in-cluster scanning of running workloads
- **SBOM**: Software Bill of Materials generation for supply chain visibility
- **Misconfiguration**: Detects insecure K8s manifests and Dockerfiles

## Related

- [Kyverno](kyverno.md) — Can enforce policies based on Trivy scan results
- [Tetragon](tetragon.md) — Runtime security (Trivy handles pre-deployment scanning)
- [GitHub Actions](github-actions.md) — Trivy runs as a CI step
- [Shift-Left Security](../concepts/shift-left.md) — Trivy enables early vulnerability detection

## Docs

- [Trivy Documentation](https://aquasecurity.github.io/trivy/)
- [Trivy Operator](https://aquasecurity.github.io/trivy-operator/)
