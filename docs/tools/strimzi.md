# Strimzi

Kubernetes operator for running Apache Kafka natively on Kubernetes.

## Why Strimzi

Strimzi manages the full lifecycle of Kafka clusters using Kubernetes CRDs — creation, scaling, rolling updates, TLS, and authentication. Chosen over Confluent Operator for its fully open-source nature and CNCF sandbox status. Chosen over manual Kafka deployment for its Kubernetes-native lifecycle management and GitOps compatibility.

## Role in This Project

- **Kafka Operator**: Manages Kafka brokers, ZooKeeper (or KRaft), topics, and users via CRDs
- **Kafka Cluster**: Multi-broker deployment for event streaming and async communication
- **Kafka UI**: Web console for topic inspection, message browsing, and consumer group management
- **GitOps Managed**: Kafka cluster configuration declared in Helm charts, deployed via ArgoCD sync waves
- **Network Policies**: Broker-to-broker and client-to-broker communication secured with CiliumNetworkPolicy

## Related

- [ArgoCD](argocd.md) — Deploys Strimzi operator and Kafka cluster via sync waves
- [Cilium](cilium.md) — Network policies for Kafka broker communication
- [Prometheus Stack](prometheus-stack.md) — Kafka metrics exported to Prometheus via JMX
- [Cloud Native](../concepts/cloud-native.md) — CNCF sandbox project, Kubernetes-native operator pattern
- [GitOps](../concepts/gitops.md) — Kafka configuration managed declaratively in Git

## Docs

- [Strimzi Documentation](https://strimzi.io/documentation/)
- [Strimzi Operators](https://strimzi.io/docs/operators/latest/overview)
- [Apache Kafka Documentation](https://kafka.apache.org/documentation/)
