# Tetragon

eBPF-based runtime security observability and enforcement.

## Why Tetragon

Tetragon hooks directly into the Linux kernel via eBPF to observe process execution, file access, and network activity — without sidecars or kernel modules. Provides deeper visibility than audit logs with lower overhead than Falco's kernel module approach.

## Role in This Project

- **Process Monitoring**: Tracks process execution, syscalls, and privilege escalation attempts
- **Runtime Enforcement**: Can block suspicious operations (not just alert)
- **Network Visibility**: Correlates network flows with processes (complements Hubble's pod-level view)
- **Security Policies**: TracingPolicy CRDs define what to observe and enforce

Part of the [Cilium](cilium.md) ecosystem — shares the same eBPF foundation.

## Related

- [Cilium](cilium.md) — Same eBPF ecosystem, handles network-level security
- [Kyverno](kyverno.md) — Admission-time policy (Tetragon handles runtime)
- [Trivy](trivy.md) — Image scanning (Tetragon handles what happens after deployment)
- [Zero Trust](../concepts/zero-trust.md) — Runtime enforcement layer
- [Shift-Left Security](../concepts/shift-left.md) — Runtime security as the last defense line

## Docs

- [Tetragon Documentation](https://tetragon.io/docs/)
- [TracingPolicy Reference](https://tetragon.io/docs/concepts/tracing-policy/)
