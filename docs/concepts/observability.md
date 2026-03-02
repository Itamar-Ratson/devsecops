# Observability

Metrics, logs, and traces — understanding system behavior from its outputs.

## What Is Observability

Observability is the ability to understand a system's internal state from its external outputs. Unlike traditional monitoring (which checks known failure modes), observability enables investigating *unknown* failures by correlating signals across metrics, logs, and traces.

**Three pillars:**
1. **Metrics** — Numeric measurements over time (CPU usage, request latency, error rates)
2. **Logs** — Timestamped event records (application output, audit trails)
3. **Traces** — Request paths through distributed systems (which services handled a request, how long each took)

## How This Project Implements Observability

### The LGTM Stack

| Pillar | Collection | Storage | Query |
|--------|-----------|---------|-------|
| **Metrics** | Prometheus scrape | Prometheus | PromQL |
| **Logs** | Alloy | Loki | LogQL |
| **Traces** | OpenTelemetry SDK | Tempo | TraceQL |
| **Visualization** | — | — | Grafana |

### Correlation

Grafana correlates all three pillars: click a metric spike → see logs from that time window → jump to the trace that caused it. This is what makes observability more powerful than isolated monitoring tools.

### What's Observed

- **Kubernetes**: Node/pod metrics, container logs, API server audit
- **Cilium**: Network flows, policy drops, DNS queries (via Hubble)
- **Applications**: Custom metrics and traces via OpenTelemetry
- **Infrastructure**: Vault audit logs, ArgoCD sync status

### Alerting

Alertmanager routes alerts based on Prometheus rules. Supports PagerDuty integration for on-call notification.

## Tools

- [Prometheus + Grafana Stack](../tools/prometheus-stack.md) — Collection, storage, and visualization
- [OpenTelemetry](../tools/opentelemetry.md) — Vendor-neutral instrumentation
- [Cilium](../tools/cilium.md) — Hubble provides network observability

## Further Reading

- [Grafana LGTM Stack](https://grafana.com/oss/)
- [OpenTelemetry Concepts](https://opentelemetry.io/docs/concepts/)
