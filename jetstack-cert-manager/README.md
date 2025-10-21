```bash
helm repo add jetstack https://charts.jetstack.io
helm repo update
```

```bash
helm install cert-manager jetstack/cert-manager \
  --version v1.15.3 \   # (or latest version)
  --set crds.enabled=true
  --namespace cert-manager \
  --create-namespace
```

```bash
kubectl create secret generic cloudflare-api-token \
  --from-literal=api-token=<YOUR_CLOUDFLARE_API_TOKEN> \
  -n dozerdb-ns
```