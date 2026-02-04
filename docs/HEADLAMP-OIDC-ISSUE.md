# Headlamp OIDC Authentication Issue

**Status:** RESOLVED
**Date:** 2026-02-04
**Components:** Headlamp, Keycloak, kube-oidc-proxy, Cilium Network Policies, trust-manager

## Original Symptoms

1. User logs in to Headlamp at https://headlamp.localhost
2. Keycloak login page appears and accepts credentials (testuser/testuser)
3. After successful authentication, user briefly sees Headlamp UI
4. Within seconds, user gets "Lost connection to cluster" error
5. User is redirected back to login page
6. Cycle repeats indefinitely

## Root Causes Identified

The issue had **multiple layers**:

### 1. Kubernetes API Server Not Configured for OIDC
The Kubernetes API server doesn't validate OIDC tokens by default. We solved this using **kube-oidc-proxy** instead of reconfiguring the API server (which would require cluster recreation).

### 2. Network Policy Port Mismatch
Cilium network policies operate at the pod level (L3/L4). When Headlamp connects to the kube-oidc-proxy Service on port 443, the traffic is NATed to the pod's port 8443. The egress policy was using port 443, but needed port 8443.

### 3. TLS Certificate Verification Failed
Go's client-go library hardcodes the ServiceAccount CA path at `/var/run/secrets/kubernetes.io/serviceaccount/ca.crt`. When we redirected Kubernetes API traffic to kube-oidc-proxy (which has a certificate signed by our internal CA), verification failed because the ServiceAccount CA only contains the Kubernetes CA, not our gateway CA.

The `SSL_CERT_FILE` environment variable doesn't help because client-go explicitly reads the CA from the ServiceAccount path, ignoring this variable.

### 4. Projected Volume Cannot Be Overlaid
Kubernetes mounts `/var/run/secrets/kubernetes.io/serviceaccount` as a projected volume. You cannot mount a file over a file within a projected volume - attempting this causes the container to fail with "not a directory" error.

## Solution Implemented

### Architecture

```
User Browser
    │
    ▼
Headlamp (in-cluster mode)
    │ KUBERNETES_SERVICE_HOST=kube-oidc-proxy.kube-oidc-proxy.svc
    │ KUBERNETES_SERVICE_PORT=443
    ▼
kube-oidc-proxy (validates OIDC tokens, impersonates users)
    │
    ▼
Kubernetes API Server
```

### Key Components

#### 1. kube-oidc-proxy Deployment
- Validates OIDC tokens from Keycloak
- Impersonates authenticated users when forwarding requests to the real API server
- Uses TCP probes (not HTTP) since it returns 401 for unauthenticated requests

**Files:**
- `helm/kube-oidc-proxy/` - Complete Helm chart

#### 2. Combined CA Bundle via trust-manager
Added Kubernetes CA to the gateway-ca-bundle so applications can verify both Kubernetes API server and internal certificates.

**File:** `helm/trust-manager/templates/ca-bundle.yaml`
```yaml
spec:
  sources:
    - secret:
        name: root-ca-secret
        key: ca.crt
    - configMap:
        name: kube-root-ca.crt  # Kubernetes CA
        key: ca.crt
```

#### 3. Custom Projected Volume for Headlamp
Disabled `automountServiceAccountToken` and created a custom projected volume that includes:
- ServiceAccount token (from `serviceAccountToken` source)
- Combined CA bundle (from `gateway-ca-bundle` configMap)
- Namespace (from downward API)

**File:** `helm/headlamp/values.yaml`
```yaml
headlamp:
  automountServiceAccountToken: false

  volumes:
    - name: custom-sa
      projected:
        sources:
          - serviceAccountToken:
              path: token
              expirationSeconds: 3600
          - configMap:
              name: gateway-ca-bundle
              items:
                - key: ca.crt
                  path: ca.crt
          - downwardAPI:
              items:
                - path: namespace
                  fieldRef:
                    fieldPath: metadata.namespace

  volumeMounts:
    - name: custom-sa
      mountPath: /var/run/secrets/kubernetes.io/serviceaccount
      readOnly: true

  env:
    - name: KUBERNETES_SERVICE_HOST
      value: kube-oidc-proxy.kube-oidc-proxy.svc
    - name: KUBERNETES_SERVICE_PORT
      value: "443"
```

#### 4. Network Policies
Bidirectional rules allowing traffic between Headlamp and kube-oidc-proxy on port 8443 (the pod port, not service port).

**Files:**
- `helm/headlamp/templates/networkpolicy.yaml` - Egress to kube-oidc-proxy:8443
- `helm/kube-oidc-proxy/templates/networkpolicy.yaml` - Ingress from Headlamp:8443

#### 5. Centralized Port Configuration
Added kube-oidc-proxy port to the centralized ports configuration.

**File:** `helm/ports.yaml`
```yaml
kubeOidcProxy:
  https: 8443
```

## Files Changed

| File | Purpose |
|------|---------|
| `helm/kube-oidc-proxy/` | New Helm chart for kube-oidc-proxy |
| `helm/headlamp/values.yaml` | Custom projected volume, env vars |
| `helm/headlamp/templates/networkpolicy.yaml` | Egress rule for kube-oidc-proxy |
| `helm/trust-manager/templates/ca-bundle.yaml` | Added Kubernetes CA source |
| `helm/ports.yaml` | Added kubeOidcProxy.https: 8443 |
| `helm/argocd/templates/applications/kube-oidc-proxy.yaml` | ArgoCD Application |
| `scripts/setup.sh` | Added kube-oidc-proxy to VSO namespaces |

## Key Learnings

1. **Cilium network policies use pod ports, not service ports** - When using `toEndpoints` with `toPorts`, specify the destination pod's listening port (8443), not the Service port (443).

2. **Go's client-go ignores SSL_CERT_FILE** - It explicitly reads CA from `/var/run/secrets/kubernetes.io/serviceaccount/ca.crt`. To use a custom CA, you must replace the entire projected volume.

3. **Projected volumes cannot be partially overlaid** - You must disable `automountServiceAccountToken` and create your own projected volume with all required files (token, ca.crt, namespace).

4. **trust-manager can combine multiple CA sources** - Use multiple sources in a Bundle to create a combined CA bundle that works for multiple backends.

5. **kube-oidc-proxy uses TCP probes** - HTTP probes fail because unauthenticated requests return 401. Use `tcpSocket` probes on port 8443.

## Verification

After cluster recreation, verify:

```bash
# 1. Check kube-oidc-proxy is running
kubectl get pods -n kube-oidc-proxy

# 2. Check combined CA bundle has 2 certificates
kubectl get configmap gateway-ca-bundle -n headlamp -o jsonpath='{.data.ca\.crt}' | grep -c "BEGIN CERTIFICATE"
# Should output: 2

# 3. Check Headlamp can reach kube-oidc-proxy (401 is expected)
kubectl exec -n headlamp deploy/headlamp -- wget -qS https://kube-oidc-proxy.kube-oidc-proxy.svc:443/ 2>&1 | head -1
# Should output: HTTP/1.1 401 Unauthorized

# 4. Check Headlamp logs for TLS errors
kubectl logs -n headlamp deploy/headlamp --tail=20 | grep -i tls
# Should be empty (no TLS errors)
```

## Environment

- Keycloak: 24.0 (Quarkus-based)
- Headlamp: v0.28.0 (also works with v0.39.0 - see below)
- kube-oidc-proxy: v0.3.0
- Kubernetes: KinD cluster v1.31.2
- CNI: Cilium with Gateway API
- TLS: cert-manager with self-signed CA
- Secret Management: Vault Secrets Operator (VSO)

## Version Compatibility

The solution works with both Headlamp v0.28.0 and v0.39.0. The original "Lost connection to cluster" error was primarily caused by the TLS verification issue, not Headlamp version bugs.

## Related GitHub Issues

- [#3143](https://github.com/kubernetes-sigs/headlamp/issues/3143) - "OIDC token refresh is not working"
- [#3961](https://github.com/kubernetes-sigs/headlamp/issues/3961) - Multi-cluster refresh token issue
- [#4134](https://github.com/kubernetes-sigs/headlamp/issues/4134) - "Can't get OIDC to Azure EntraID refresh token"
- [#4198](https://github.com/kubernetes-sigs/headlamp/issues/4198) - Impersonation header issue
