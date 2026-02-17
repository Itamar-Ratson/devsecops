# CI Pipeline

Security-focused CI pipeline for the DevSecOps project. Builds, scans, deploys to an ephemeral KinD cluster, runs DAST scans, and tears everything down.

## Triggers

- **Push** to `main` (matching paths: `helm/`, `docker/`, `terraform/`, `.github/`)
- **Pull request** to `main` (same paths)
- **Manual** via `gh workflow run juice-shop-security.yaml`

## Jobs

| Job | Purpose |
|-----|---------|
| `build` | Build and push Juice Shop container image to GHCR |
| `container-scan` | Trivy vulnerability scan on the container image |
| `iac-scan` | Trivy IaC scan on Helm charts and Terraform |
| `helm-lint` | Helm lint and template validation |
| `kyverno-test` | Pod Security Standards validation via Kyverno CLI |
| `terraform-validate` | `terraform fmt` and `validate` on all modules |
| `deployment-and-dast` | Full KinD deploy + ArgoCD sync + ZAP baseline/full scans + teardown |

The first six jobs run in parallel. `deployment-and-dast` runs after all pass.

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

## Permissions

```yaml
contents: read
packages: write
security-events: write
pull-requests: write
```

## Structure

```
.github/
  workflows/
    juice-shop-security.yaml   # Main pipeline
  scripts/
    ci-warm-zot.sh              # GHCR -> Zot (start of CI)
    ci-save-images.sh           # KinD nodes -> GHCR (end of CI)
  zap/
    rules.tsv                   # ZAP scan rule overrides
```
