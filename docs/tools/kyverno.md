# Kyverno

Kubernetes-native policy engine for admission control, mutation, and generation.

## Why Kyverno

Kyverno uses Kubernetes-native YAML policies instead of a separate policy language (unlike OPA/Gatekeeper's Rego). This makes policies readable and reviewable by the same team that writes K8s manifests. Chosen over OPA/Gatekeeper for lower learning curve and native K8s integration.

## Role in This Project

- **Pod Security**: Enforces Pod Security Standards (restricted/baseline profiles)
- **Image Policies**: Validates container image sources and tags
- **Resource Validation**: Enforces labels, resource limits, and naming conventions
- **Policy Reports**: ClusterPolicyReport CRDs provide audit visibility

## Related

- [Tetragon](tetragon.md) — Runtime enforcement (Kyverno handles admission-time)
- [Trivy](trivy.md) — Image scanning (Kyverno enforces image policies)
- [Policy as Code](../concepts/policy-as-code.md) — Kyverno is the admission-time policy engine
- [Least Privilege](../concepts/least-privilege.md) — Pod security restrictions enforce minimal capabilities
- [Zero Trust](../concepts/zero-trust.md) — Admission control layer
- [Shift-Left Security](../concepts/shift-left.md) — Policy enforcement at deploy time

## Docs

- [Kyverno Documentation](https://kyverno.io/docs/)
- [Policy Library](https://kyverno.io/policies/)
