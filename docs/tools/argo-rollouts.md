# Argo Rollouts

Progressive delivery controller for Kubernetes — canary, blue-green, and traffic-weighted deployments.

## Why Argo Rollouts

Argo Rollouts extends Kubernetes Deployments with advanced rollout strategies that the native Deployment controller doesn't support. It integrates with service meshes and ingress controllers for traffic management. Chosen as a natural companion to ArgoCD for safe, automated deployments.

## Role in This Project

- **Canary Deployments**: Gradually shift traffic to new versions with automated analysis
- **Blue-Green**: Zero-downtime deployments with instant rollback
- **Traffic Management**: Integrates with Gateway API for traffic splitting
- **Analysis Runs**: Automated rollback based on Prometheus metrics

## Related

- [ArgoCD](argocd.md) — Triggers rollouts via GitOps sync
- [Prometheus Stack](prometheus-stack.md) — Provides metrics for rollout analysis
- [Gateway API](gateway-api.md) — Traffic splitting for canary deployments

## Docs

- [Argo Rollouts Documentation](https://argoproj.github.io/argo-rollouts/)
- [Traffic Management](https://argoproj.github.io/argo-rollouts/features/traffic-management/)
