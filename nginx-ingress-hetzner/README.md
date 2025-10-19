# NGINX Ingress for Hetzner Cloud

Production-ready NGINX Ingress Controller configuration for Hetzner Cloud Kubernetes.

## Installation

```bash
# Add Helm repo (first time only)
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

# Install
helm install nginx-ingress ingress-nginx/ingress-nginx \
  -n ingress-nginx --create-namespace -f values.yaml

# Get Load Balancer IP (wait 1-2 minutes)
kubectl get svc -n ingress-nginx
```

## What's Included

- Hetzner Load Balancer (lb11 - €5.50/month)
- PROXY protocol (preserves client IPs)
- Default ingress class
- Single replica

## Customization

**Scale replicas:**
```bash
--set controller.replicaCount=2
```

**Change load balancer size:**
```bash
--set controller.service.annotations."load-balancer\.hetzner\.cloud/type"=lb21
```

Options: `lb11` (€5.50) | `lb21` (€11.90) | `lb31` (€18.30)

**Custom values file:**
```bash
helm install nginx-ingress ingress-nginx/ingress-nginx \
  -n ingress-nginx --create-namespace \
  -f values.yaml -f my-custom.yaml
```

## Management

**Upgrade:**
```bash
helm upgrade nginx-ingress ingress-nginx/ingress-nginx -n ingress-nginx -f values.yaml
```

**Uninstall:**
```bash
helm uninstall nginx-ingress -n ingress-nginx
```

## Resources

- [NGINX Ingress Docs](https://kubernetes.github.io/ingress-nginx/)
- [Hetzner Cloud Controller](https://github.com/hetznercloud/hcloud-cloud-controller-manager)
