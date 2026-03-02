# Cosign

Container image signing and verification using keyless signatures via Sigstore.

## Why Cosign

Cosign provides cryptographic signing of container images without managing private keys. Using keyless signing via Sigstore's Fulcio CA, it ties image signatures to CI identity (GitHub Actions OIDC) — proving an image was built by a specific workflow in a specific repository.

## Role in This Project

- **Keyless Signing**: Container images are signed in CI using GitHub Actions' OIDC identity — no key management
- **Provenance**: Signatures prove an image was built by this project's CI pipeline, not by an attacker
- **Transparency Log**: Signatures are recorded in Sigstore's Rekor transparency log for public auditability
- **Verification**: Images can be verified before deployment to ensure they haven't been tampered with

## Related

- [GitHub Actions](github-actions.md) — Cosign runs as a CI step after image build
- [Trivy](trivy.md) — Scans images for vulnerabilities (Cosign ensures integrity)
- [Kyverno](kyverno.md) — Can enforce signature verification at admission time
- [Supply Chain Security](../concepts/supply-chain-security.md) — Cosign provides image provenance and integrity
- [Shift-Left Security](../concepts/shift-left.md) — Signing happens at build time

## Docs

- [Cosign Documentation](https://docs.sigstore.dev/cosign/overview/)
- [Sigstore](https://www.sigstore.dev/)
- [Keyless Signing](https://docs.sigstore.dev/cosign/signing/signing_with_containers/)
