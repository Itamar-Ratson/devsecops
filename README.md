# Kubernetes Local Dev Setup

KinD + Cilium (CNI + Gateway) + Gateway API + cert-manager + Sealed Secrets + Hubble + Tetragon + Network Policies + Monitoring (Prometheus + Grafana + Loki + Alloy + Tempo)

## Prerequisites

Docker, kubectl, Helm, KinD, kubeseal

## Setup

```bash
# Increase inotify limits (required for Hubble mTLS and monitoring stack)
# Current usage: ~100 instances, ~400 watches per node
# These provide comfortable headroom without being excessive
sudo sysctl -w fs.inotify.max_user_instances=1024
sudo sysctl -w fs.inotify.max_user_watches=16384

# To make permanent, add to /etc/sysctl.conf:
# fs.inotify.max_user_instances=1024
# fs.inotify.max_user_watches=16384

# Create Kind cluster with disabled CNI
kind create cluster --config kind-config.yaml

# Install all CRDs upfront (best practice: CRDs define APIs, apps implement them)
# This allows faster Helm operations and better version control

# Gateway API CRDs (experimental required for Cilium)
# Cilium's Gateway controller requires TLSRoute and other experimental CRDs
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.2.1/experimental-install.yaml

# Prometheus Operator CRDs (required before Cilium for ServiceMonitors)
kubectl apply -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.87.1/example/prometheus-operator-crd/monitoring.coreos.com_servicemonitors.yaml
kubectl apply --server-side -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.87.1/example/prometheus-operator-crd/monitoring.coreos.com_prometheuses.yaml
kubectl apply --server-side -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.87.1/example/prometheus-operator-crd/monitoring.coreos.com_alertmanagers.yaml
kubectl apply --server-side -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.87.1/example/prometheus-operator-crd/monitoring.coreos.com_podmonitors.yaml
kubectl apply --server-side -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.87.1/example/prometheus-operator-crd/monitoring.coreos.com_prometheusrules.yaml

# cert-manager CRDs (recommended by cert-manager docs for production)
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.19.2/cert-manager.crds.yaml

# Install Cilium as CNI and Gateway controller
# Note: kubeProxyReplacement must be enabled for Gateway API support
helm dependency build ./helm/cilium
helm upgrade --install cilium ./helm/cilium -n kube-system
kubectl wait --for=condition=Ready nodes --all --timeout=300s

# Install Tetragon for security observability
helm dependency build ./helm/tetragon
helm upgrade --install tetragon ./helm/tetragon -n kube-system \
  -f ./helm/ports.yaml \
  -f ./helm/tetragon/values.yaml \
  -f ./helm/tetragon/values-tetragon.yaml
kubectl rollout status -n kube-system ds/tetragon -w

# Install cert-manager for TLS certificate management
helm dependency build ./helm/cert-manager
helm upgrade --install cert-manager ./helm/cert-manager -n cert-manager --create-namespace
kubectl wait --for=condition=Available deployment/cert-manager -n cert-manager --timeout=120s

# Install sealed-secrets for secret management
helm dependency build ./helm/sealed-secrets
helm upgrade --install sealed-secrets ./helm/sealed-secrets -n sealed-secrets --create-namespace

# Install Gateway and test application
helm upgrade --install gateway ./helm/gateway -n gateway --create-namespace
helm upgrade --install http-echo ./helm/http-echo -n http-echo --create-namespace

# Install network policies for security
helm upgrade --install network-policies ./helm/network-policies

# Install monitoring stack (Prometheus + Grafana + Loki + Alloy + Tempo)
# Note: Uses split values files for better organization
# IMPORTANT: All values files must be explicitly specified with -f flags
helm dependency build ./helm/monitoring
helm upgrade --install monitoring ./helm/monitoring -n monitoring --create-namespace \
  -f ./helm/monitoring/values.yaml \
  -f ./helm/monitoring/values-kube-prometheus.yaml \
  -f ./helm/monitoring/values-loki.yaml \
  -f ./helm/monitoring/values-alloy.yaml \
  -f ./helm/monitoring/values-tempo.yaml

# Test the setup
sleep 3
curl -k https://echo.localhost
curl -k https://hubble.localhost
curl -k https://grafana.localhost
```

## Monitoring with Grafana and Prometheus

The setup includes a complete monitoring stack with Prometheus, Grafana, Loki (log aggregation), Alloy (log collection), and Tempo (distributed tracing), featuring official dashboards from grafana.com.

**📖 [Read the comprehensive Monitoring Stack Guide](MONITORING.md)** - Learn how the monitoring stack works, how metrics are collected, troubleshooting techniques, and how to add custom metrics.

### Accessing Grafana

Grafana is exposed through the Gateway at: **https://grafana.localhost**

- **Username**: `admin`
- **Password**: `admin` (change after first login)

### Available Dashboards

The monitoring stack includes official dashboards from grafana.com:

**Cilium Dashboards:**
1. **Cilium Metrics** (Dashboard ID: 16611)
   - Cilium Agent performance metrics
   - BPF subsystem stats
   - API call latency and counts
   - Network forwarding metrics
   - Conntrack entries

2. **Cilium Operator** (Dashboard ID: 16612)
   - Operator-specific metrics
   - Controller reconciliation stats
   - Resource management

3. **Hubble Metrics** (Dashboard ID: 16613)
   - Network flow metrics
   - DNS query statistics
   - HTTP/TCP traffic analysis
   - Drop reasons and packet flows
   - Service map visualization

**Loki Dashboard:**
4. **Loki Stack Monitoring** (Dashboard ID: 14055)
   - Log ingestion rate (lines/sec and bytes/sec)
   - Active log streams
   - Query performance and latency
   - Loki component resource usage
   - Memcached cache statistics

**Tempo Dashboard:**
5. **OpenTelemetry & Tempo** (Dashboard ID: 23242)
   - Tempo querier, writer, and cache metrics
   - Query latency and throughput
   - Block compaction and retention
   - Trace ingestion performance
   - OpenTelemetry receiver/processor/exporter metrics
   - Tail sampling processor statistics

### Metrics Configuration

Prometheus metrics are enabled for:
- **Cilium Agent**: Port 9962
- **Cilium Operator**: Port 9963
- **Hubble**: Port 9965
- **Hubble Relay**: Port 4245
- **Envoy Proxy**: Port 9091

All metrics are automatically discovered via ServiceMonitors configured in `helm/cilium/values.yaml`:
```yaml
prometheus:
  enabled: true
  serviceMonitor:
    enabled: true
hubble:
  metrics:
    enabled:
      - dns:query
      - drop
      - tcp
      - flow
      - port-distribution
      - icmp
      - httpV2:exemplars=true
```

### Prometheus Access

Prometheus is available for direct querying:
```bash
# Port-forward to Prometheus
kubectl port-forward -n monitoring svc/monitoring-kube-prometheus-prometheus 9090:9090

# Then open: http://localhost:9090
```

### AlertManager Integration

AlertManager is configured as a datasource in Grafana for managing and viewing alerts:

- **Access**: Navigate to **Alerting** → **Alert rules** in Grafana
- **Datasource**: AlertManager is pre-configured and accessible via Grafana
- **Features**:
  - View active alerts
  - Create silences
  - Configure contact points (notification destinations)
  - View alert history

The monitoring stack includes default alerting rules for:
- Kubernetes cluster health
- Node resource usage
- Pod status and health
- Prometheus and monitoring stack health

### Data Retention

- **Prometheus**: 2 days with 2GB limit (5Gi storage allocated)
- **AlertManager**: 24 hours (2Gi storage)
- **Grafana**: Persistent storage (1Gi)
- **Loki**: 48 hours (2 days) with 2GB limit (2Gi storage)
- **Tempo**: 24 hours (2Gi storage)

### Testing Distributed Tracing

To test the distributed tracing pipeline and populate Tempo with sample traces:

```bash
# Create namespace for test workloads
kubectl create namespace trace-test

# Run trace generator (generates 5 traces/second for 2 hours)
kubectl run trace-generator -n trace-test \
  --image=ghcr.io/open-telemetry/opentelemetry-collector-contrib/telemetrygen:latest \
  --restart=Never \
  -- traces --otlp-endpoint=alloy.monitoring:4317 --otlp-insecure --rate=5 --duration=7200s

# Verify traces are being received
kubectl logs -n trace-test trace-generator

# Query Tempo for traces
kubectl exec -n monitoring deploy/grafana -c grafana -- \
  wget -qO- 'http://tempo:3200/api/search?tags=service.name=telemetrygen&limit=10'

# View traces in Grafana
# Open https://grafana.localhost → Explore → Select "Tempo" datasource → Query: {service.name="telemetrygen"}
```

**Note**: Logs are automatically collected by Alloy from all pods cluster-wide, so no log generator is needed. The trace generator is only necessary because applications must actively instrument and send traces using OpenTelemetry SDKs.

## Key Configuration Requirements

### Cilium Gateway API Support

For Cilium to act as a Gateway controller, the following must be configured in `helm/cilium/values.yaml`:

1. **kube-proxy replacement**: `kubeProxyReplacement: true` - Required for Gateway API
2. **Gateway API enabled**: `gatewayAPI.enabled: true`
3. **Host networking**: `gatewayAPI.hostNetwork.enabled: true` - For Kind clusters

### Gateway API CRDs

Cilium requires the **experimental** Gateway API CRDs (not just standard):
- Includes `TLSRoute`, `TCPRoute`, `UDPRoute` needed by Cilium's controller
- Standard install only includes `HTTPRoute` and `GRPCRoute`

### Troubleshooting

If the Gateway shows `PROGRAMMED: Unknown`:

1. Check Cilium operator logs:
   ```bash
   kubectl logs -n kube-system deployment/cilium-operator | grep -i gateway
   ```

2. Verify kube-proxy-replacement is enabled:
   ```bash
   kubectl get configmap cilium-config -n kube-system -o yaml | grep kube-proxy-replacement
   ```

3. Verify all required CRDs are installed:
   ```bash
   kubectl get crd | grep gateway.networking.k8s.io
   ```
   Should include: `tlsroutes.gateway.networking.k8s.io`

## Hubble - Network Observability

Hubble provides deep network visibility and monitoring for your Kubernetes cluster.

### Features

- **Service Map**: Real-time visualization of service dependencies
- **Flow Monitoring**: Observe all network traffic between pods
- **Security**: Identify blocked connections and policy violations
- **Troubleshooting**: Debug connectivity issues

### Accessing Hubble UI

Hubble UI is exposed through the Gateway at: **https://hubble.localhost**

Open your browser and navigate to the URL to:
- View the service dependency map
- Monitor network flows in real-time
- Inspect DNS requests and responses
- Debug network policy denials

### Configuration

Hubble is configured in `helm/cilium/values.yaml:22`:
```yaml
hubble:
  enabled: true
  relay:
    enabled: true  # Aggregates flows from all Cilium instances
  ui:
    enabled: true  # Web interface
```

## Tetragon - Security Observability

Tetragon provides deep kernel-level security observability and runtime enforcement using eBPF.

**📖 [Read the comprehensive Tetragon Guide](TETRAGON.md)** - Learn how Tetragon works, what it monitors, security policies, and troubleshooting techniques.

### Features

- **Process Monitoring**: Track all process executions, arguments, and genealogy
- **System Call Tracing**: Monitor security-critical syscalls (file access, privilege escalation)
- **File I/O Tracking**: Observe file access patterns and sensitive file operations
- **Runtime Enforcement**: Block malicious activities at the kernel level with eBPF
- **Kubernetes Context**: Enriches events with pod, namespace, and label metadata
- **Low Overhead**: < 1% performance impact using in-kernel filtering

### How Tetragon Complements Hubble

- **Hubble**: Network-level observability (L3/L4/L7 traffic flows between pods)
- **Tetragon**: System-level observability (processes, syscalls, file I/O within pods)

Together they provide comprehensive visibility from network to system level.

### Accessing Tetragon Events

Tetragon events are automatically collected by Alloy and stored in Loki:

1. Open Grafana: **https://grafana.localhost**
2. Go to **Explore** → Select **Loki** datasource
3. Example queries:
   ```
   # All Tetragon events
   {namespace="kube-system", app="tetragon"}

   # Process executions
   {namespace="kube-system", app="tetragon"} |= "process_exec"

   # File access events
   {namespace="kube-system", app="tetragon"} |= "process_kprobe" |= "fd_install"
   ```

### Metrics

Tetragon exposes Prometheus metrics automatically scraped via ServiceMonitors:
- **Agent metrics**: Port 2112
- **Operator metrics**: Port 2113

Access metrics in Grafana or Prometheus UI.

### Using the Tetra CLI (Optional)

For interactive event querying, install the tetra CLI:

```bash
# Install tetra CLI
GOOS=$(go env GOOS)
GOARCH=$(go env GOARCH)
curl -L https://github.com/cilium/tetragon/releases/latest/download/tetra-${GOOS}-${GOARCH}.tar.gz | tar -xz
sudo mv tetra /usr/local/bin

# Port-forward to Tetragon
kubectl port-forward -n kube-system ds/tetragon 54321:54321 &

# Query live events
tetra getevents -o compact

# Filter specific event types
tetra getevents -o compact --event-types process_exec
```

## Network Policies

The cluster implements **Cilium Network Policies** for defense-in-depth security.

**📖 [Read the comprehensive Network Policies Guide](NETWORK_POLICIES.md)** - Learn how Cilium network policies work, common patterns, debugging techniques, and real examples from this project.

### Security Model

Each namespace has:
1. **Default deny all**: Blocks all ingress and egress traffic by default
2. **Allow rules**: Explicitly permit only required traffic

### Implemented Policies

#### http-echo namespace
- ✅ Allows ingress from Cilium Gateway only (`fromEntities: [ingress]`)
- ✅ Allows DNS egress to kube-dns
- ❌ All other traffic blocked

#### cert-manager namespace
- ✅ Allows egress to Kubernetes API server (`toEntities: [kube-apiserver]`)
- ✅ Allows DNS egress
- ✅ Allows webhook ingress from API server
- ❌ All other traffic blocked

#### sealed-secrets namespace
- ✅ Allows egress to Kubernetes API server
- ✅ Allows DNS egress
- ✅ Allows controller ingress for kubeseal CLI and webhooks
- ❌ All other traffic blocked

#### monitoring namespace
- ✅ Allows Prometheus to scrape metrics from all monitoring components and kube-system
- ✅ Allows Grafana to access Prometheus, AlertManager, and Loki datasources
- ✅ Allows Loki components (gateway, single-binary, memcached, canary) to communicate
- ✅ Allows Alloy daemonset to send logs to Loki Gateway
- ✅ Allows DNS egress and API server access
- ❌ All other traffic blocked

### Why Cilium Network Policies?

We use **Cilium Network Policies** instead of standard Kubernetes NetworkPolicies because:

- **Host Network Support**: Cilium Gateway runs with `hostNetwork: true`, which standard K8s policies can't handle effectively
- **Special Entities**: Cilium supports entities like `ingress`, `host`, and `kube-apiserver` for precise matching
- **Better Integration**: Native support for Cilium-specific features and identities

### Verification

Check policy enforcement:
```bash
# List all Cilium network policies
kubectl get ciliumnetworkpolicies -A

# Check endpoint policy status
kubectl exec -n kube-system ds/cilium -- cilium endpoint list
```

### Location

Network policies are defined in:
- `helm/http-echo/templates/networkpolicy.yaml` - http-echo policies
- `helm/network-policies/templates/` - cert-manager and sealed-secrets policies
- `helm/monitoring/templates/networkpolicy/` - monitoring stack policies (24 policies across 12 files)

## Cleanup

```bash
kind delete cluster --name k8s-dev
```
