# DevOps

Breaking down silos between development and operations through culture, automation, and shared ownership.

## What Is DevOps

DevOps is a cultural and technical movement that unifies software development (Dev) and IT operations (Ops). Instead of separate teams throwing work over the wall, DevOps promotes shared responsibility for the full software lifecycle — from writing code to running it in production.

**Core practices:**
1. **Continuous Integration** — Merge and test code frequently
2. **Continuous Delivery** — Automate the path from code to production
3. **Infrastructure as Code** — Manage infrastructure with the same rigor as application code
4. **Monitoring and Feedback** — Observe production, feed insights back to development
5. **Collaboration** — Shared ownership, no "that's not my job"

## How This Project Demonstrates DevOps

### Automation Over Manual Work

Nothing in this project requires manual steps. The full lifecycle is automated:

```
Code commit → CI validation → Merge → ArgoCD sync → Running in cluster
```

Infrastructure follows the same path:

```
Terraform change → Plan review → Apply → Cluster provisioned
```

### Single Repository

Infrastructure (Terraform), platform (Helm charts), policies (CiliumNetworkPolicy, Kyverno), and CI/CD (GitHub Actions) all live in the same repository. Changes to any layer follow the same workflow: branch → PR → review → merge → deploy.

### Feedback Loops

- **CI** provides immediate feedback on code quality, security, and infrastructure validity
- **ArgoCD** shows sync status and drift — you know instantly if reality matches intent
- **Prometheus + Grafana** provides production metrics back to developers
- **Hubble** shows network flows — developers can debug connectivity without ops involvement

### Self-Service Infrastructure

ArgoCD's app-of-apps pattern means adding a new service is self-service: create a Helm chart, add an Application manifest, commit. No tickets, no handoffs.

## Related Concepts

- [DevSecOps](devsecops.md) — Extends DevOps with embedded security
- [CI/CD](ci-cd.md) — The automation backbone of DevOps
- [GitOps](gitops.md) — Git-driven delivery model
- [Infrastructure as Code](infrastructure-as-code.md) — Codified infrastructure management

## Further Reading

- [The Phoenix Project](https://itrevolution.com/the-phoenix-project/) — The DevOps novel
- [DORA Metrics](https://dora.dev/) — Measuring DevOps performance
- [Google SRE Book](https://sre.google/sre-book/table-of-contents/) — Operations at scale
