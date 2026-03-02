# Supply Chain Security

Securing the software supply chain — from source code to running container.

## What Is Supply Chain Security

Software supply chain security ensures that every artifact in the delivery pipeline — source code, dependencies, container images, Helm charts — is trustworthy, unmodified, and free of known vulnerabilities. Attacks like SolarWinds and Log4Shell demonstrated that compromising a single dependency can compromise thousands of downstream systems.

**Key concerns:**
1. **Provenance** — Where did this artifact come from?
2. **Integrity** — Has it been tampered with?
3. **Vulnerabilities** — Does it contain known security issues?
4. **Transparency** — What dependencies does it include?

## How This Project Implements Supply Chain Security

### Image Signing (Cosign)

Container images built in CI are signed using Cosign's keyless signing via Sigstore. This provides cryptographic proof that an image was built by the project's CI pipeline and hasn't been modified since.

```
Build image → Sign with Cosign (keyless) → Push to registry
    → Verify signature before deploy
```

### Software Bill of Materials (Syft)

Syft generates SBOMs for every built image, listing all packages, libraries, and their versions. This enables rapid response when a new CVE is disclosed — you can immediately check if you're affected.

### Vulnerability Scanning (Trivy)

Trivy scans at two points:
- **CI time**: Scans images during build, failing the pipeline on critical CVEs
- **Runtime**: Trivy Operator continuously scans running workloads for newly disclosed CVEs

### Registry Security (Zot)

A local OCI-compliant registry with pull-through caching reduces dependency on external registries and provides a controlled artifact store.

### Admission Control (Kyverno)

Kyverno policies can enforce that only signed images from trusted registries are deployed, closing the loop between signing and verification.

## Related Concepts

- [Shift-Left Security](shift-left.md) — Scanning in CI is shift-left for the supply chain
- [DevSecOps](devsecops.md) — Supply chain security is a DevSecOps practice
- [Zero Trust](zero-trust.md) — Don't trust artifacts implicitly

## Tools

- [Trivy](../tools/trivy.md) — Vulnerability scanning
- [Kyverno](../tools/kyverno.md) — Image policy enforcement
- [GitHub Actions](../tools/github-actions.md) — Cosign signing and Syft SBOM in CI

## Further Reading

- [SLSA Framework](https://slsa.dev/) — Supply chain Levels for Software Artifacts
- [Sigstore](https://www.sigstore.dev/) — Keyless signing and transparency logs
- [in-toto](https://in-toto.io/) — Supply chain layout and verification
