# kube-oidc-proxy

Reverse proxy that authenticates OIDC tokens for the Kubernetes API server.

## Why kube-oidc-proxy

kube-oidc-proxy sits between clients and the Kubernetes API server, validating OIDC tokens and passing authenticated identity to the API server for RBAC decisions. This enables OIDC authentication on clusters that don't natively support it (like KinD) without modifying API server flags.

## Role in This Project

- **OIDC Bridge**: Validates tokens from Keycloak and forwards authenticated requests to the K8s API
- **Dashboard SSO**: Enables Headlamp to authenticate users via Keycloak without direct API server OIDC configuration
- **KinD Compatibility**: KinD doesn't support OIDC flags natively — kube-oidc-proxy works around this
- **Identity Chain**: Headlamp/Grafana → kube-oidc-proxy → Keycloak → Kubernetes RBAC

## Related

- [Keycloak](keycloak.md) — OIDC identity provider that issues the tokens
- [Headlamp](headlamp.md) — Dashboard that authenticates through kube-oidc-proxy
- [cert-manager](cert-manager.md) — TLS certificates for the proxy endpoint
- [Zero Trust](../concepts/zero-trust.md) — Identity verification before API access
- [Least Privilege](../concepts/least-privilege.md) — RBAC decisions based on verified OIDC identity

## Docs

- [kube-oidc-proxy](https://github.com/jetstack/kube-oidc-proxy)
