# Prometheus + Grafana Stack

Full observability stack: metrics, logs, traces, and dashboards.

## Components

| Component | Role |
|-----------|------|
| **Prometheus** | Metrics collection via scrape-based pull model |
| **Grafana** | Visualization and dashboards |
| **Loki** | Log aggregation with label-based indexing |
| **Tempo** | Distributed tracing backend |
| **Alloy** | Telemetry collector (replaces Promtail/Agent) |
| **Alertmanager** | Alert routing and deduplication |

## Why This Stack

The Grafana LGTM stack (Loki, Grafana, Tempo, Mimir/Prometheus) provides a unified observability platform with a single query language (LogQL/PromQL) and correlated views across metrics, logs, and traces. Chosen over Datadog/New Relic for its open-source nature and self-hosted control. Alloy replaces the older Promtail + Grafana Agent with a single OpenTelemetry-compatible collector.

## Role in This Project

- **Metrics**: Prometheus scrapes all K8s components, Cilium, and application endpoints
- **Logs**: Alloy ships container logs to Loki
- **Traces**: Applications send traces via OpenTelemetry to Tempo
- **Dashboards**: Pre-configured Grafana dashboards for Cilium, Kubernetes, and application metrics
- **Alerting**: Alertmanager routes alerts (PagerDuty integration available)

## Related

- [OpenTelemetry](opentelemetry.md) — Vendor-neutral instrumentation feeding into this stack
- [Observability](../concepts/observability.md) — The concept behind this stack

## Docs

- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/grafana/latest/)
- [Loki Documentation](https://grafana.com/docs/loki/latest/)
- [Tempo Documentation](https://grafana.com/docs/tempo/latest/)
- [Alloy Documentation](https://grafana.com/docs/alloy/latest/)
