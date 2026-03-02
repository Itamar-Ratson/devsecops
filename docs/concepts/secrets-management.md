# Secrets Management

Secure lifecycle for credentials, API keys, and sensitive configuration.

## What Is Secrets Management

Secrets management is the practice of securely storing, distributing, rotating, and auditing access to sensitive data (passwords, API keys, certificates, tokens). The goal: no secrets in code, no secrets in plain text, every access logged.

**Core principles:**
1. **Centralized** — Single source of truth for secrets
2. **Encrypted at rest and in transit** — Secrets never stored in plain text
3. **Least privilege** — Applications only access the secrets they need
4. **Audited** — Every secret access is logged
5. **Rotatable** — Secrets can be rotated without redeploying applications

## How This Project Implements Secrets Management

### Two-Tier Architecture

| Tier | Tool | Purpose |
|------|------|---------|
| **Primary** | HashiCorp Vault + VSO | Dynamic secrets, centralized management, audit logging |
| **Bootstrap** | Sealed Secrets | Secrets needed before Vault is available (chicken-and-egg) |

### Vault Flow

```
Pod (ServiceAccount) → Kubernetes Auth → Vault → Secret
    ↓
Vault Secrets Operator → Kubernetes Secret → Pod Volume/Env
```

1. **Kubernetes Auth**: Pods authenticate to Vault using their ServiceAccount JWT — no static credentials
2. **Vault Secrets Operator (VSO)**: Watches VaultStaticSecret CRDs and syncs secrets into K8s Secrets
3. **Transit Engine**: External Vault provides encryption-as-a-service for auto-unseal

### What's Stored in Vault

- Keycloak OIDC client secrets
- Grafana admin credentials
- Webhook tokens
- Service-to-service credentials

### Sealed Secrets Flow

```
kubeseal (encrypt with public key) → SealedSecret in Git → Controller (decrypt) → K8s Secret
```

Used for bootstrap secrets that must exist in Git before Vault is running.

### Rules

- No secrets in Helm values files (use Vault references or SealedSecrets)
- No secrets in Terraform state (use Vault transit encryption)
- No secrets in environment variables visible in pod specs

## Tools

- [Vault](../tools/vault.md) — Primary secrets manager
- [Sealed Secrets](../tools/sealed-secrets.md) — Git-safe encrypted secrets
- [cert-manager](../tools/cert-manager.md) — TLS certificate lifecycle (a type of secret)

## Further Reading

- [Vault Secrets Operator](https://developer.hashicorp.com/vault/docs/platform/k8s/vso)
- [Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets)
