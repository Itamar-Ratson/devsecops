# Headlamp

Extensible, web-based Kubernetes dashboard.

## Why Headlamp

Headlamp provides a clean, modern UI for Kubernetes cluster management with plugin extensibility and OIDC authentication support. Chosen over the default Kubernetes Dashboard for its active development, better UX, and native OIDC integration for SSO.

## Role in This Project

- **Cluster Visibility**: Web UI for viewing workloads, pods, services, and cluster state
- **OIDC Login**: Users authenticate via Keycloak through kube-oidc-proxy — no kubeconfig distribution needed
- **RBAC-Scoped Views**: Users see only what their OIDC identity is authorized to access
- **Plugin Support**: Extensible with plugins for custom views and functionality

The authentication chain: Headlamp → kube-oidc-proxy → Keycloak → Kubernetes RBAC.

## Related

- [Keycloak](keycloak.md) — OIDC identity provider for Headlamp login
- [Prometheus Stack](prometheus-stack.md) — Grafana provides metrics dashboards (Headlamp provides K8s resource views)
- [Least Privilege](../concepts/least-privilege.md) — RBAC-scoped views per user identity
- [Zero Trust](../concepts/zero-trust.md) — Identity-based access to the dashboard
- [Observability](../concepts/observability.md) — UI layer for cluster visibility

## Docs

- [Headlamp Documentation](https://headlamp.dev/docs/latest/)
- [Headlamp Plugins](https://headlamp.dev/docs/latest/development/plugins/)
