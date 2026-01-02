# Kubernetes Local Dev Setup (Gateway API)

Local development setup using KinD, Cilium (with WireGuard encryption), Traefik, Helm, cert-manager, Sealed Secrets, and Kubernetes Gateway API.

## Prerequisites

- Docker
- kubectl
- Helm
- KinD
- kubeseal

## 1. Create KinD Cluster

```bash
kind create cluster --config kind-config.yaml
```

The cluster won't be Ready until a CNI is installed (next step).

## 2. Install Cilium (CNI with WireGuard Encryption)

```bash
helm repo add cilium https://helm.cilium.io
helm repo update
helm dependency build ./helm/cilium
helm install cilium ./helm/cilium -n kube-system -f ./helm/cilium/values.yaml
kubectl wait --for=condition=Ready nodes --all --timeout=300s
```

Verify encryption:

```bash
kubectl -n kube-system exec ds/cilium -- cilium-dbg encrypt status
```

## 3. Install Gateway API CRDs

```bash
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.2.1/standard-install.yaml
```

## 4. Install cert-manager

```bash
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm dependency build ./helm/cert-manager
helm upgrade --install cert-manager ./helm/cert-manager -n cert-manager --create-namespace
kubectl wait --for=condition=Available deployment/cert-manager -n cert-manager --timeout=120s
```

## 5. Install Sealed Secrets

```bash
helm repo add sealed-secrets https://bitnami-labs.github.io/sealed-secrets
helm repo update
helm dependency build ./helm/sealed-secrets
helm upgrade --install sealed-secrets ./helm/sealed-secrets -n sealed-secrets --create-namespace
kubectl wait --for=condition=Available deployment/sealed-secrets -n sealed-secrets --timeout=120s
```

Verify:

```bash
kubeseal --controller-name sealed-secrets --controller-namespace sealed-secrets --fetch-cert
```

## 6. Install Traefik

```bash
helm repo add traefik https://traefik.github.io/charts
helm repo update
helm dependency build ./helm/traefik
helm upgrade --install traefik ./helm/traefik -n traefik --create-namespace
kubectl wait --for=condition=Available deployment/traefik -n traefik --timeout=120s
```

## 7. Install http-echo (Test App)

```bash
helm upgrade --install http-echo ./helm/http-echo -n http-echo --create-namespace
```

Test: `curl -k https://echo.localhost`

## Troubleshooting

### Verify Cilium encryption

```bash
kubectl -n kube-system exec ds/cilium -- cilium-dbg encrypt status
```

### Check Gateway status

```bash
kubectl get gateway -n traefik
```

### Check HTTPRoute status

```bash
kubectl get httproute -A
```

### Check certificate

```bash
kubectl get certificate -n traefik
```

### Traefik logs

```bash
kubectl logs -n traefik -l app.kubernetes.io/name=traefik
```

## Cleanup

```bash
kind delete cluster --name k8s-dev
```
