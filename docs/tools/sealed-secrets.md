# Sealed Secrets

Encrypt Kubernetes Secrets for safe storage in Git.

## Why Sealed Secrets

Sealed Secrets allows encrypting K8s Secret manifests with a cluster-side controller's public key, so the encrypted form can be safely committed to Git. Only the controller (with the private key) can decrypt them. Used alongside Vault for secrets that need to exist in Git (bootstrap secrets, ArgoCD configs).

## Role in This Project

- **Bootstrap Secrets**: Secrets needed before Vault is available (chicken-and-egg problem)
- **Git-Safe Secrets**: Encrypted SealedSecret resources committed alongside Helm charts
- **Controller**: Runs in-cluster, decrypts SealedSecrets into regular K8s Secrets

## Related

- [Vault](vault.md) — Primary secrets manager (Sealed Secrets is complementary)
- [Secrets Management](../concepts/secrets-management.md) — Part of the two-tier secrets strategy

## Docs

- [Sealed Secrets Documentation](https://github.com/bitnami-labs/sealed-secrets)
