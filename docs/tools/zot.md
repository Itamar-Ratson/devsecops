# Zot

Lightweight, OCI-native container registry with no external dependencies.

## Why Zot

Zot is a minimal, OCI-compliant registry that supports image storage, pull-through caching, and OCI artifacts — all in a single binary with no database dependency. Chosen over Harbor for its simplicity and low resource footprint, and over Docker Registry for its native OCI support and active development.

## Role in This Project

- **Pull-Through Cache**: Caches images from upstream registries (Docker Hub, GHCR), reducing external dependencies and avoiding rate limits
- **Registry Warm**: Pre-populated with commonly used images so cluster bootstraps don't depend on external connectivity
- **OCI Artifacts**: Can store Helm charts, SBOMs, and signed images alongside container images
- **Air-Gap Friendly**: Local registry enables offline/air-gapped deployments

## Related

- [Trivy](trivy.md) — Scans images stored in Zot
- [Crossplane](crossplane.md) — Provider packages pulled through Zot
- [Supply Chain Security](../concepts/supply-chain-security.md) — Local registry as a controlled artifact store
- [Cloud Native](../concepts/cloud-native.md) — OCI-compliant registry for cloud-native workflows

## Docs

- [Zot Documentation](https://zotregistry.dev/docs/)
- [OCI Distribution Spec](https://github.com/opencontainers/distribution-spec)
