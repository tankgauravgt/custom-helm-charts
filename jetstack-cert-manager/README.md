# Jetstack Cert-Manager

Automated certificate management for Kubernetes, enabling Let's Encrypt SSL/TLS certificates.

## Installation

### Step 1: Add Helm Repository

```bash
helm repo add jetstack https://charts.jetstack.io
helm repo update
```

### Step 2: Install Cert-Manager

```bash
helm install cert-manager jetstack/cert-manager \
  --version v1.15.3 \
  --namespace cert-manager \
  --create-namespace \
  --set crds.enabled=true \
  --set resources.requests.cpu=10m \
  --set resources.requests.memory=32Mi \
  --set resources.limits.cpu=50m \
  --set resources.limits.memory=64Mi \
  --set webhook.resources.requests.cpu=10m \
  --set webhook.resources.requests.memory=32Mi \
  --set webhook.resources.limits.cpu=50m \
  --set webhook.resources.limits.memory=64Mi \
  --set cainjector.resources.requests.cpu=10m \
  --set cainjector.resources.requests.memory=32Mi \
  --set cainjector.resources.limits.cpu=50m \
  --set cainjector.resources.limits.memory=64Mi
```

### Step 3: Verify Installation

```bash
kubectl get pods -n cert-manager
```

All three pods should be running:
- `cert-manager` - Main controller
- `cert-manager-webhook` - Admission webhook
- `cert-manager-cainjector` - CA injection controller

## Configuration for DozerDB

### Create Cloudflare API Token Secret

Replace `<YOUR_CLOUDFLARE_API_TOKEN>` with your actual token:

```bash
kubectl create secret generic cloudflare-api-token \
  --from-literal=api-token=<YOUR_CLOUDFLARE_API_TOKEN> \
  --namespace dozerdb-ns
```

### Cloudflare API Token Permissions

Your Cloudflare API token needs:
- **Zone:DNS:Edit** - To create DNS records for verification
- **Zone:Zone:Read** - To read zone information

## Features

- **Automatic certificate renewal** - Renews certificates before expiry
- **Multiple DNS providers** - Supports Cloudflare, Route53, Google Cloud DNS, etc.
- **HTTP-01 and DNS-01 challenges** - Flexible verification methods
- **Low resource usage** - Optimized for small clusters

## Next Steps

After installing cert-manager:
1. Create an Issuer or ClusterIssuer (see DozerDB configuration)
2. Create Certificate resources
3. Cert-manager automatically issues and renews certificates