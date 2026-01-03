# Kubernetes Local Dev Setup

KinD + Cilium (CNI + Gateway) + Gateway API + cert-manager + Sealed Secrets

## Prerequisites

Docker, kubectl, Helm, KinD, kubeseal

## Setup

```bash
kind create cluster --config kind-config.yaml
helm dependency build ./helm/cilium
helm install cilium ./helm/cilium -n kube-system
kubectl wait --for=condition=Ready nodes --all --timeout=300s
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.2.1/standard-install.yaml
helm dependency build ./helm/cert-manager
helm upgrade --install cert-manager ./helm/cert-manager -n cert-manager --create-namespace
kubectl wait --for=condition=Available deployment/cert-manager -n cert-manager --timeout=120s
helm dependency build ./helm/sealed-secrets
helm upgrade --install sealed-secrets ./helm/sealed-secrets -n sealed-secrets --create-namespace
helm upgrade --install gateway ./helm/gateway -n gateway --create-namespace
helm upgrade --install http-echo ./helm/http-echo -n http-echo --create-namespace
sleep 3
curl -k https://echo.localhost
```

## Cleanup

```bash
kind delete cluster --name k8s-dev
```
