# Keycloak

Open-source identity and access management providing OpenID Connect (OIDC).

## Why Keycloak

Keycloak provides enterprise-grade identity management with support for OIDC, SAML, LDAP, and social login. Chosen over Dex for its full-featured admin console, user management, and richer protocol support.

## Role in This Project

- **OIDC Provider**: Central identity provider for all services requiring authentication
- **Headlamp SSO**: Users authenticate to the Kubernetes dashboard via Keycloak
- **Grafana SSO**: Grafana delegates authentication to Keycloak
- **kube-oidc-proxy**: Proxies OIDC tokens to the Kubernetes API server, enabling RBAC based on Keycloak identity

The OIDC chain: User → Headlamp/Grafana → kube-oidc-proxy → Keycloak → K8s RBAC.

## Related

- [Vault](vault.md) — Stores Keycloak client secrets
- [cert-manager](cert-manager.md) — TLS certificates for OIDC endpoints
- [Zero Trust](../concepts/zero-trust.md) — Identity-based access control
- [Least Privilege](../concepts/least-privilege.md) — RBAC scoped by OIDC identity

## Docs

- [Keycloak Documentation](https://www.keycloak.org/documentation)
- [kube-oidc-proxy](https://github.com/jetstack/kube-oidc-proxy)
