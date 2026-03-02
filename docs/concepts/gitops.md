# GitOps

Git as the single source of truth for declarative infrastructure and application delivery.

## What Is GitOps

GitOps is an operational model where the desired state of the entire system is declared in Git. A reconciliation agent continuously compares Git (desired) with the live system (actual), and corrects any drift. Changes happen through pull requests — not manual commands.

**Core principles:**
1. **Declarative** — The entire system is described declaratively
2. **Versioned** — Desired state is stored in Git (versioned, auditable, revertible)
3. **Automated** — Approved changes are applied automatically
4. **Reconciled** — Agents continuously ensure actual state matches desired state

## How This Project Implements GitOps

### Two-Phase Bootstrap

Terraform/Terragrunt handles what can't be GitOps (cluster creation, CNI, CRDs). Once ArgoCD is running, it takes over and manages itself + everything else.

```
Terraform (imperative bootstrap) → ArgoCD (declarative reconciliation)
```

### App-of-Apps Pattern

A single root ArgoCD Application points to a directory of Application manifests. Adding a new service = adding one YAML file and committing. ArgoCD discovers and deploys it automatically.

### Sync Waves

ArgoCD sync waves enforce ordering: CRDs deploy before operators, operators before workloads. This is declared in annotations, not imperative scripts.

### Strict Rules

- Never `helm install/upgrade` for ArgoCD-managed charts — edit values in Git, commit, let ArgoCD sync
- Never `kubectl patch/edit` — all changes go through Git
- Drift is flagged as out-of-sync in ArgoCD's dashboard

## Tools

- [ArgoCD](../tools/argocd.md) — GitOps reconciliation engine
- [Argo Rollouts](../tools/argo-rollouts.md) — Progressive delivery within GitOps
- [Terraform](../tools/terraform.md) — Bootstrap-phase IaC
- [GitHub Actions](../tools/github-actions.md) — CI validation before merge

## Further Reading

- [OpenGitOps Principles](https://opengitops.dev/)
- [ArgoCD Declarative Setup](https://argo-cd.readthedocs.io/en/stable/operator-manual/declarative-setup/)
