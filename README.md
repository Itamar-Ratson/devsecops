# Kubernetes Local Dev Setup

KinD + Cilium (CNI + Gateway) + Gateway API + cert-manager + Sealed Secrets + Hubble + Network Policies

## Prerequisites

Docker, kubectl, Helm, KinD, kubeseal

## Setup

```bash
# Create Kind cluster with disabled CNI
kind create cluster --config kind-config.yaml

# Install Cilium as CNI and Gateway controller
# Note: kubeProxyReplacement must be enabled for Gateway API support
helm dependency build ./helm/cilium
helm install cilium ./helm/cilium -n kube-system
kubectl wait --for=condition=Ready nodes --all --timeout=300s

# Install Gateway API CRDs (experimental required for Cilium)
# Cilium's Gateway controller requires TLSRoute and other experimental CRDs
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.2.1/experimental-install.yaml

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
helm install network-policies ./helm/network-policies

# Test the setup
sleep 3
curl -k https://echo.localhost
curl -k https://hubble.localhost
```

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

## Network Policies

The cluster implements **Cilium Network Policies** for defense-in-depth security.

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

## Cleanup

```bash
kind delete cluster --name k8s-dev
```
