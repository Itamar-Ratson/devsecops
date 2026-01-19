# Cluster Test Workflow Design

## Overview

GitHub Actions workflow that runs every 5 hours to test the full devsecops cluster deployment with new tools. Uses a phone-editable config file to control which tests run.

## Goals

1. **Automated cluster testing** - Verify the full stack deploys correctly every 5 hours
2. **New tools integration** - Add Argo Rollouts, Argo Workflows to the stack
3. **Phone-editable config** - Simple YAML file to enable/disable tests from GitHub mobile
4. **Future: Terraform** - Replace setup.sh with Terraform (Phase 2)
5. **Future: Cluster Mesh** - Multi-cluster testing (Phase 3)

## Architecture

```
.github/cluster-test-config.yaml     <- Phone-editable
         │
         ▼
.github/workflows/cluster-test.yaml  <- 5h cron + workflow_dispatch
         │
         ├── Setup Job (KinD + Cilium + ArgoCD bootstrap)
         │
         ├── Wait for ArgoCD sync (all waves)
         │
         ├── Test Jobs (from config matrix)
         │   ├── argo-rollouts-test
         │   ├── argo-workflows-test
         │   ├── network-policies-test
         │   └── ...
         │
         └── Report Job (artifacts + summary)
```

## Phone-Editable Config File

`.github/cluster-test-config.yaml`:

```yaml
# Edit this file from GitHub mobile to control tests
# Changes trigger workflow on push to main

version: 1

# Master switch - set to false to skip all tests
enabled: true

# Individual test toggles
tests:
  # Core infrastructure
  argocd-sync: true        # Wait for all ArgoCD apps to sync
  network-policies: true   # Test Cilium network policies

  # New tools (Phase 1)
  argo-rollouts: true      # Test Argo Rollouts deployment
  argo-workflows: true     # Test Argo Workflows execution

  # Existing apps
  juice-shop: true         # Test Juice Shop deployment
  http-echo: true          # Test HTTP Echo deployment

  # Observability
  monitoring: true         # Test Prometheus/Grafana stack

  # Future (Phase 3)
  cluster-mesh: false      # Multi-cluster tests (disabled)

# Workflow settings
settings:
  timeout_minutes: 60      # Max workflow duration
  continue_on_error: false # Stop on first failure
  notify_slack: false      # Slack notifications (requires secret)
```

## New Helm Charts

### helm/argo-rollouts/

Argo Rollouts for progressive delivery (blue-green, canary deployments).

```yaml
# Chart.yaml
apiVersion: v2
name: argo-rollouts
version: 0.1.0
dependencies:
  - name: argo-rollouts
    version: "2.39.0"
    repository: "https://argoproj.github.io/argo-helm"
```

ArgoCD Application (Wave 1 - independent infrastructure):
- Namespace: `argo-rollouts`
- Sync wave: 1

### helm/argo-workflows/

Argo Workflows for Kubernetes-native workflow orchestration.

```yaml
# Chart.yaml
apiVersion: v2
name: argo-workflows
version: 0.1.0
dependencies:
  - name: argo-workflows
    version: "0.45.0"
    repository: "https://argoproj.github.io/argo-helm"
```

ArgoCD Application (Wave 1 - independent infrastructure):
- Namespace: `argo-workflows`
- Sync wave: 1

## GitHub Actions Workflow

`.github/workflows/cluster-test.yaml`:

```yaml
name: Cluster Integration Test

on:
  schedule:
    - cron: '0 */5 * * *'  # Every 5 hours
  workflow_dispatch:        # Manual trigger from GitHub UI/mobile
  push:
    paths:
      - '.github/cluster-test-config.yaml'
      - '.github/workflows/cluster-test.yaml'

jobs:
  read-config:
    runs-on: ubuntu-latest
    outputs:
      enabled: ${{ steps.config.outputs.enabled }}
      tests: ${{ steps.config.outputs.tests }}
    steps:
      - uses: actions/checkout@v4
      - id: config
        run: |
          # Parse YAML config and output as JSON for matrix
          ...

  setup-cluster:
    needs: read-config
    if: needs.read-config.outputs.enabled == 'true'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Create KinD cluster
        uses: helm/kind-action@v1.12.0
        with:
          config: kind-config.yaml
      - name: Install Cilium
        run: |
          helm dependency build ./helm/cilium
          helm upgrade --install cilium ./helm/cilium -n kube-system
      - name: Bootstrap ArgoCD
        run: |
          # Simplified bootstrap for CI (no secrets needed)
          ...

  test-matrix:
    needs: [read-config, setup-cluster]
    strategy:
      matrix:
        test: ${{ fromJson(needs.read-config.outputs.tests) }}
    steps:
      - name: Run test
        run: |
          # Test-specific validation
          ...
```

## Implementation Plan

### Phase 1: Argo Tools + Workflow (This PR)

1. **Create `helm/argo-rollouts/`**
   - Chart.yaml with argo-helm dependency
   - values.yaml with minimal config
   - Network policy template
   - ArgoCD Application in helm/argocd/

2. **Create `helm/argo-workflows/`**
   - Chart.yaml with argo-helm dependency
   - values.yaml with minimal config
   - Network policy template
   - ArgoCD Application in helm/argocd/

3. **Create `.github/cluster-test-config.yaml`**
   - Phone-editable test toggles
   - Settings for timeout, error handling

4. **Create `.github/workflows/cluster-test.yaml`**
   - 5-hour cron schedule
   - workflow_dispatch for manual triggers
   - Matrix strategy from config file
   - Full cluster deployment + tests

5. **Update `helm/ports.yaml`**
   - Add ports for argo-rollouts
   - Add ports for argo-workflows

### Phase 2: Terraform - IMPLEMENTED

Terraform configuration to replace `scripts/setup.sh`:

```
terraform/
├── main.tf                          # Main configuration with variables
├── terraform.tfvars.example         # Example variables file
├── .gitignore                       # Ignore state and sensitive files
└── modules/
    ├── transit-vault/               # Docker-based Transit Vault
    ├── kind-cluster/                # KinD cluster creation
    ├── cilium/                      # Cilium CNI installation
    ├── sealed-secrets/              # Sealed Secrets controller
    ├── argocd/                      # ArgoCD with GitOps
    └── cluster-mesh/                # Multi-cluster Cluster Mesh
```

Usage:
```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
terraform init
terraform apply
```

### Phase 3: Cluster Mesh - IMPLEMENTED

Cilium Cluster Mesh configuration:

- `helm/cilium/values-clustermesh.yaml` - Cluster Mesh Helm values
- `terraform/modules/cluster-mesh/` - Multi-cluster Terraform module

To enable Cluster Mesh:
```bash
helm upgrade cilium ./helm/cilium -n kube-system \
  -f ./helm/ports.yaml \
  -f ./helm/cilium/values.yaml \
  -f ./helm/cilium/values-clustermesh.yaml \
  --set cilium.cluster.name=cluster1 \
  --set cilium.cluster.id=1
```

## File Structure (All Phases)

```
.github/
├── cluster-test-config.yaml         # Phone-editable config
├── workflows/
│   ├── cluster-test.yaml            # 5h cron workflow
│   └── juice-shop-security.yaml
helm/
├── argo-rollouts/                   # Argo Rollouts chart
│   ├── Chart.yaml
│   ├── values.yaml
│   ├── values-argo-rollouts.yaml
│   └── templates/
│       └── networkpolicy.yaml
├── argo-workflows/                  # Argo Workflows chart
│   ├── Chart.yaml
│   ├── values.yaml
│   ├── values-argo-workflows.yaml
│   └── templates/
│       └── networkpolicy.yaml
├── cilium/
│   ├── values.yaml
│   └── values-clustermesh.yaml      # Cluster Mesh config
├── argocd/
│   └── templates/applications/
│       ├── argo-rollouts.yaml
│       └── argo-workflows.yaml
└── ports.yaml                       # Updated with new ports
terraform/
├── main.tf                          # Main Terraform config
├── terraform.tfvars.example         # Example variables
├── .gitignore
└── modules/
    ├── transit-vault/main.tf
    ├── kind-cluster/main.tf
    ├── cilium/main.tf
    ├── sealed-secrets/main.tf
    ├── argocd/main.tf
    └── cluster-mesh/main.tf
docs/plans/
└── 2026-01-19-cluster-test-workflow-design.md
```

## Test Cases

### Argo Rollouts Test
1. Verify controller deployment is ready
2. Create test Rollout resource
3. Verify rollout progresses to healthy

### Argo Workflows Test
1. Verify controller deployment is ready
2. Submit test workflow
3. Verify workflow completes successfully

### ArgoCD Sync Test
1. Wait for all applications to sync
2. Verify no degraded applications
3. Check all pods are running

## Success Criteria

- [ ] Workflow runs every 5 hours
- [ ] Config file editable from GitHub mobile
- [ ] Argo Rollouts deploys via ArgoCD
- [ ] Argo Workflows deploys via ArgoCD
- [ ] All tests pass in CI
- [ ] Clear failure reporting
