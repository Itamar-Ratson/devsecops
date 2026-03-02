# OpenTelemetry

Vendor-neutral standard for telemetry collection (traces, metrics, logs).

## Why OpenTelemetry

OpenTelemetry provides a single, vendor-neutral API and SDK for instrumenting applications. This avoids lock-in to any specific observability backend. The OpenTelemetry Operator automates instrumentation injection and collector management in Kubernetes.

## Role in This Project

- **OpenTelemetry Operator**: Manages OpenTelemetry Collectors and auto-instrumentation in Kubernetes
- **Trace Collection**: Collects distributed traces and forwards them to Tempo
- **Standards Compliance**: All telemetry follows OTLP (OpenTelemetry Protocol), making backends swappable

## Related

- [Prometheus Stack](prometheus-stack.md) — Backend that receives OpenTelemetry data
- [Observability](../concepts/observability.md) — OpenTelemetry is the instrumentation standard

## Docs

- [OpenTelemetry Documentation](https://opentelemetry.io/docs/)
- [OpenTelemetry Operator](https://opentelemetry.io/docs/kubernetes/operator/)
