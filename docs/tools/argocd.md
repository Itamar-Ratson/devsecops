# ArgoCD

Declarative, GitOps continuous delivery tool for Kubernetes.

## Why ArgoCD

ArgoCD continuously reconciles the desired state in Git with the live cluster state, automatically detecting and optionally correcting drift. Chosen over Flux because of its richer UI, application-of-apps pattern, and sync wave support for ordered deployments.

## Role in This Project

- **App-of-Apps**: A single root Application deploys all other applications via sync waves
- **Sync Waves**: Ordered deployment — CRDs and operators deploy before workloads that depend on them
- **Drift Detection**: Any manual cluster change is flagged as out-of-sync
- **Two-Phase Bootstrap**: Terraform installs ArgoCD, then ArgoCD manages everything else (including itself)

The project enforces a strict rule: never `helm install` for ArgoCD-managed components. All changes go through Git.

## Related

- [GitOps](../concepts/gitops.md) — ArgoCD is the GitOps engine
- [Argo Rollouts](argo-rollouts.md) — Progressive delivery companion
- [Terraform](terraform.md) — Bootstraps ArgoCD before handoff

## Docs

- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [App of Apps Pattern](https://argo-cd.readthedocs.io/en/stable/operator-manual/cluster-bootstrapping/)
- [Sync Waves](https://argo-cd.readthedocs.io/en/stable/user-guide/sync-waves/)
