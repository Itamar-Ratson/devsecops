# CI Pipelines

Security-focused CI pipelines for the DevSecOps project.

## Workflows

### CI (`ci.yaml`)

Builds, scans, lints, and validates on every code change.

**Triggers:** push to `main`, PR to `main` (paths: `helm/`, `docker/juice-shop/`, `terraform/`, `.github/workflows/ci.yaml`), manual dispatch.

| Job | Purpose |
|-----|---------|
| `gitleaks` | Secret scanning (working tree + git history) |
| `actionlint` | GitHub Actions workflow linting |
| `build` | Build and push Juice Shop container image to GHCR, cosign signing, SBOM |
| `container-scan` | Trivy vulnerability scan on the container image |
| `iac-scan` | Trivy IaC scan on Helm charts and Terraform |
| `helm-lint` | Helm lint, kubeconform validation, chart version checks |
| `kyverno-test` | Pod Security Standards validation via Kyverno CLI |
| `terraform-validate` | `terraform fmt` and `validate` on all modules |

### Deployment and DAST (`deployment-and-dast.yaml`)

Deploys to an ephemeral KinD cluster, runs DAST scans, tears everything down.

**Triggers:** weekdays 3 AM UTC, manual dispatch.

| Job | Purpose |
|-----|---------|
| `deployment-and-dast` | Full KinD deploy + ArgoCD sync + ZAP baseline/full scans + teardown |

### Pipeline Self-Test (`pipeline-test.yaml`)

Validates pipeline health: tool download URLs, checksums, and Helm template rendering.

**Triggers:** push to `main`, PR to `main` (paths: `.github/workflows/**`), manual dispatch.

| Job | Purpose |
|-----|---------|
| `workflow-lint` | actionlint on all workflow files |
| `tool-smoke-test` | Download + version-check for all pinned tool binaries (Gitleaks, kubeconform, Kyverno, Helm, Terragrunt, Crane, Cosign) |
| `helm-chain-check` | Helm template + kubeconform validation of juice-shop |

## Image Cache

CI uses GHCR as persistent image cache across runs to avoid pulling all images from upstream registries every time.

**How it works:**

1. **Warm** (start of deploy) -- `.github/scripts/ci-warm-zot.sh` pulls cached images from `ghcr.io/<owner>/devsecops/mirror/` into the local Zot registry so containerd serves them on cache hit.
2. **Save** (end of deploy) -- `.github/scripts/ci-save-images.sh` collects images from KinD nodes and pushes them to GHCR. Stale packages no longer used by the cluster are deleted.

First run pulls everything from upstream (slow). Subsequent runs hit the GHCR cache (fast).

## Secrets

| Secret | Required | Purpose |
|--------|----------|---------|
| `GITHUB_TOKEN` | Auto | Container image push/pull, SARIF uploads, artifact management |
| `PACKAGES_PAT` | Yes | Classic PAT with `read:packages` + `delete:packages` for GHCR cache management via GitHub API |

## Tool Version Management

Inline tool versions in workflow `run:` blocks are tracked by Renovate via `# renovate:` annotation comments. Adding a new tool only requires a comment above the version line — no `renovate.json` changes needed.

## Structure

```
.github/
  workflows/
    ci.yaml                     # Main CI pipeline
    deployment-and-dast.yaml    # DAST scanning pipeline
    pipeline-test.yaml          # Pipeline health checks
  scripts/
    ci-warm-zot.sh              # GHCR -> Zot (start of CI)
    ci-save-images.sh           # KinD nodes -> GHCR (end of CI)
  zap/
    rules.tsv                   # ZAP scan rule overrides
```
