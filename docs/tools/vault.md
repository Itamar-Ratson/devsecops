# HashiCorp Vault

Secrets management, encryption as a service, and identity-based access.

## Why Vault

Vault provides centralized secrets management with fine-grained access control, audit logging, and dynamic secrets. Chosen over AWS Secrets Manager or SOPS for its portability across cloud providers and its transit encryption engine.

## Role in This Project

- **Transit Vault**: Runs as an external Docker container, providing encryption-as-a-service for auto-unseal and key management
- **Vault Secrets Operator (VSO)**: Syncs secrets from Vault into Kubernetes Secrets, keeping them up-to-date automatically
- **OIDC Secrets**: Stores Keycloak client secrets, Grafana admin credentials, and webhook tokens
- **Kubernetes Auth**: Pods authenticate to Vault using their ServiceAccount tokens — no static credentials

## Related

- [Sealed Secrets](sealed-secrets.md) — Complementary approach for encrypting secrets in Git
- [Keycloak](keycloak.md) — OIDC secrets stored in Vault
- [Secrets Management](../concepts/secrets-management.md) — Vault is the core of the secrets strategy
- [Terraform](terraform.md) — Provisions and configures Vault

## Docs

- [Vault Documentation](https://developer.hashicorp.com/vault/docs)
- [Vault Secrets Operator](https://developer.hashicorp.com/vault/docs/platform/k8s/vso)
- [Transit Secrets Engine](https://developer.hashicorp.com/vault/docs/secrets/transit)
