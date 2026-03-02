# eBPF

Programmable kernel technology enabling high-performance networking, security, and observability without kernel modules.

## What Is eBPF

eBPF (extended Berkeley Packet Filter) allows running sandboxed programs inside the Linux kernel without modifying kernel source code or loading kernel modules. Originally designed for packet filtering, it now powers networking, security, tracing, and observability at kernel-level performance.

**Why it matters:**
- **Performance** — Runs in kernel space, avoids context switches to userspace
- **Safety** — eBPF programs are verified before execution, can't crash the kernel
- **No sidecars** — Network policies and tracing happen at the kernel level, not in application proxies
- **Dynamic** — Programs can be loaded/unloaded at runtime without restarts

## How This Project Uses eBPF

### Cilium (Networking + Security)

Cilium replaces kube-proxy and iptables with eBPF programs that handle:
- **Packet forwarding** — Pod-to-pod, pod-to-service, and external traffic
- **Network policy enforcement** — L3/L4/L7 filtering at the kernel level
- **Load balancing** — Service load balancing without iptables chains
- **Hubble** — Network flow observability by tapping eBPF data paths

### Tetragon (Runtime Security)

Tetragon attaches eBPF programs to kernel functions to observe:
- **Process execution** — Every `exec()` call, with full process tree
- **File access** — Reads/writes to sensitive files
- **Network connections** — Correlates network flows with processes
- **Syscalls** — Monitors and can block specific system calls

### Why Not Traditional Approaches

| Approach | Drawback | eBPF Advantage |
|----------|----------|----------------|
| iptables (kube-proxy) | O(n) rule matching, slow at scale | O(1) hash-based lookup |
| Sidecar proxies (Istio) | Per-pod overhead, latency | Kernel-level, no extra containers |
| Kernel modules (Falco) | Risk of kernel crashes, complex updates | Verified programs, safe by design |
| Userspace agents | Context switch overhead | Runs in kernel, minimal overhead |

## Tools

- [Cilium](../tools/cilium.md) — eBPF-based CNI, network policies, and observability
- [Tetragon](../tools/tetragon.md) — eBPF-based runtime security

## Further Reading

- [ebpf.io](https://ebpf.io/) — The eBPF community site
- [What is eBPF? (Brendan Gregg)](https://www.brendangregg.com/ebpf.html)
- [Cilium eBPF Documentation](https://docs.cilium.io/en/stable/bpf/)
