```bash
helm repo add hcloud https://charts.hetzner.cloud
helm repo update
```

```bash
helm upgrade --install hcloud-csi hcloud/hcloud-csi -n kube-system --values hetzner-csi.yaml
```

```bash
kubectl get pods -n kube-system -l app.kubernetes.io/name=hcloud-csi
```

```bash
kubectl get storageclass hcloud-volumes
```
