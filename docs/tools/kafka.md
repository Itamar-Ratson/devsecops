# Strimzi Kafka

Kubernetes-native Apache Kafka operator for event streaming.

## Why Strimzi

Strimzi manages Apache Kafka clusters on Kubernetes using CRDs, handling broker configuration, scaling, rolling updates, and security. Chosen over self-managed Kafka for its Kubernetes-native lifecycle management and GitOps compatibility.

## Role in This Project

- **Strimzi Operator**: Manages Kafka cluster lifecycle via Kubernetes CRDs
- **Kafka Cluster**: Multi-broker Kafka deployment for event streaming
- **Kafka UI**: Web console for topic management and message inspection
- **GitOps Managed**: Kafka cluster configuration lives in Git, deployed via ArgoCD

## Related

- [ArgoCD](argocd.md) — Deploys Kafka resources via sync waves
- [Cilium](cilium.md) — Network policies for Kafka broker communication
- [Prometheus Stack](prometheus-stack.md) — Kafka metrics exported to Prometheus

## Docs

- [Strimzi Documentation](https://strimzi.io/documentation/)
- [Apache Kafka Documentation](https://kafka.apache.org/documentation/)
