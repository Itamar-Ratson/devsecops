# Kubernetes Local Dev Setup

KinD + Cilium (CNI + Gateway) + Gateway API + cert-manager + Sealed Secrets

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

# Test the setup
sleep 3
curl -k https://echo.localhost
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

## Cleanup

```bash
kind delete cluster --name k8s-dev
```
