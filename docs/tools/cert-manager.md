# cert-manager + trust-manager

Automated certificate lifecycle management and CA bundle distribution.

## Why cert-manager

cert-manager automates TLS certificate issuance and renewal from sources like Let's Encrypt, Vault, and self-signed CAs. It's the de facto standard for certificate management in Kubernetes. trust-manager distributes CA bundles across namespaces, ensuring all workloads trust the right CAs.

## Role in This Project

- **Certificate Issuance**: Automated TLS certificates for Gateway API routes and internal services
- **CA Bundles**: trust-manager distributes CA bundles so services can validate each other's certificates
- **Vault Integration**: Can issue certificates via Vault's PKI secrets engine
- **Let's Encrypt**: Production certificates for external-facing services

## Related

- [Vault](vault.md) — PKI backend for internal certificates
- [Gateway API](gateway-api.md) — TLS termination uses cert-manager certificates
- [Keycloak](keycloak.md) — OIDC endpoints require trusted TLS

## Docs

- [cert-manager Documentation](https://cert-manager.io/docs/)
- [trust-manager Documentation](https://cert-manager.io/docs/trust/trust-manager/)
