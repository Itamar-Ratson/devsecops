# Cloud Native

Building and running applications that exploit the advantages of cloud computing — containers, microservices, declarative APIs, and automation.

## What Is Cloud Native

Cloud native is an approach to building systems that are designed for cloud environments from the start. As defined by the CNCF (Cloud Native Computing Foundation), cloud native technologies enable organizations to build and run scalable applications in dynamic environments like public, private, and hybrid clouds.

**Key characteristics:**
1. **Containerized** — Packaged in OCI containers for consistency across environments
2. **Dynamically orchestrated** — Managed by Kubernetes for scheduling, scaling, and healing
3. **Microservices-oriented** — Loosely coupled services with clear boundaries
4. **Declarative** — Desired state described in manifests, not imperative scripts
5. **Observable** — Built-in metrics, logs, and traces

## How This Project Is Cloud Native

### Kubernetes-Native Everything

Every component runs on Kubernetes and is managed through Kubernetes APIs:
- Workloads are Deployments/StatefulSets
- Configuration is ConfigMaps/Secrets
- Networking is Gateway API + CiliumNetworkPolicy
- Infrastructure is Crossplane CRDs
- Policies are Kyverno ClusterPolicy

### CNCF Landscape Coverage

This project uses tools from across the [CNCF landscape](https://landscape.cncf.io/):

| Category | CNCF Project | Status |
|----------|-------------|--------|
| Container Runtime | containerd | Graduated |
| Orchestration | Kubernetes | Graduated |
| CNI | Cilium | Graduated |
| Service Mesh | Cilium (Gateway API) | Graduated |
| Observability | Prometheus, OpenTelemetry | Graduated |
| GitOps | ArgoCD | Graduated |
| Secrets | cert-manager | Graduated |
| Policy | Kyverno | Incubating |
| Security | Tetragon | Incubating |
| IaC | Crossplane | Graduated |
| Streaming | Strimzi (Kafka) | CNCF Sandbox |

### Multi-Environment Portability

The same Helm charts and Terraform modules deploy to both KinD (local Docker) and EKS (AWS). Cloud native design means the application layer doesn't change — only the infrastructure underneath.

## Related Concepts

- [DevOps](devops.md) — Cloud native enables DevOps practices at scale
- [Infrastructure as Code](infrastructure-as-code.md) — Declarative infrastructure for cloud environments
- [Observability](observability.md) — Built-in visibility into cloud native systems
- [GitOps](gitops.md) — Declarative delivery for cloud native applications

## Further Reading

- [CNCF Cloud Native Definition](https://github.com/cncf/toc/blob/main/DEFINITION.md)
- [CNCF Landscape](https://landscape.cncf.io/)
- [The Twelve-Factor App](https://12factor.net/)
