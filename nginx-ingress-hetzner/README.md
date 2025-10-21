# NGINX Ingress Controller for Hetzner Cloud

Production-ready NGINX Ingress Controller configuration optimized for Hetzner Cloud Kubernetes clusters.

## Features

- ✅ Hetzner Cloud Load Balancer integration (lb11 - €5.50/month)
- ✅ PROXY protocol support (preserves client IP addresses)
- ✅ Optimized resource allocation for cost efficiency
- ✅ Node affinity for specific instance types
- ✅ High availability with pod anti-affinity

## Installation

### Step 1: Add Helm Repository

```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
```

### Step 2: Install NGINX Ingress

```bash
helm install nginx-ingress ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --values values.yaml
```

### Step 3: Get Load Balancer IP

Wait 1-2 minutes for the load balancer to provision, then:

```bash
kubectl get svc -n ingress-nginx
```

Look for the `EXTERNAL-IP` value - this is your load balancer's public IP.

## Configuration

### Load Balancer Types

The configuration uses Hetzner Load Balancer type `lb11` by default. You can change this in `values.yaml` or via Helm:

| Type | Monthly Cost | Max Connections | Max Targets |
|------|-------------|-----------------|-------------|
| lb11 | €5.50       | 20,000          | 25          |
| lb21 | €11.90      | 40,000          | 25          |
| lb31 | €18.30      | 60,000          | 25          |

### Scaling Replicas

For high availability, increase the number of controller replicas:

```bash
helm upgrade nginx-ingress ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --reuse-values \
  --set controller.replicaCount=2
```

### Custom Values

You can override settings by creating your own values file:

```bash
helm install nginx-ingress ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --values values.yaml \
  --values my-custom-values.yaml
```

## Management

### Upgrade

```bash
helm upgrade nginx-ingress ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --values values.yaml
```

### View Configuration

```bash
helm get values nginx-ingress -n ingress-nginx
```

### Uninstall

```bash
helm uninstall nginx-ingress -n ingress-nginx
```

**Note**: This will also delete the Hetzner Load Balancer.

## Usage Example

Create an Ingress resource to route traffic:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: example-ingress
  namespace: default
spec:
  ingressClassName: nginx
  rules:
    - host: example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: example-service
                port:
                  number: 80
```

## Troubleshooting

### Check Controller Logs

```bash
kubectl logs -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx
```

### Verify Load Balancer

```bash
kubectl describe svc -n ingress-nginx nginx-ingress-ingress-nginx-controller
```

### Test PROXY Protocol

Ensure client IPs are preserved:

```bash
kubectl logs -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx | grep "X-Forwarded-For"
```

## Resources

- [NGINX Ingress Documentation](https://kubernetes.github.io/ingress-nginx/)
- [Hetzner Cloud Controller Manager](https://github.com/hetznercloud/hcloud-cloud-controller-manager)
- [Hetzner Load Balancer Docs](https://docs.hetzner.com/cloud/load-balancers/overview/)
