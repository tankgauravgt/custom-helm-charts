# DozerDB on Hetzner Cloud

Production-ready DozerDB (Neo4j-based graph database) deployment on Hetzner Cloud Kubernetes with SSL/TLS encryption and persistent storage.

## Features

- ✅ SSL/TLS encryption for HTTPS and Bolt connections
- ✅ Automatic HTTP to HTTPS redirection (sidecar pattern)
- ✅ **Single LoadBalancer** for all traffic (cost-effective!)
- ✅ Automatic Let's Encrypt certificate management
- ✅ Persistent storage with Hetzner Cloud Volumes
- ✅ APOC plugin pre-installed
- ✅ StatefulSet for data persistence

## 💰 Cost Optimization

This setup uses **only ONE LoadBalancer** to handle all traffic (HTTP, HTTPS, and Bolt). The HTTP to HTTPS redirection is handled by a lightweight nginx sidecar running in the same pod as DozerDB.

**Cost savings**: Eliminates the need for a second LoadBalancer or NGINX Ingress Controller!

## Prerequisites

Before deploying DozerDB, ensure you have:

1. **Kubernetes cluster** on Hetzner Cloud
2. **Hetzner CSI Driver** installed (for persistent volumes)
3. **Cert-Manager** installed (for SSL certificates)
4. **Cloudflare account** with API token
5. **Domain name** managed by Cloudflare

## Configuration

### Step 1: Update Placeholders

Edit the following files and replace placeholders:

**`02-cloudflare-api-token.yaml`**
```yaml
api-token: {{ API_TOKEN_PLACEHOLDER }}
# Replace with your Cloudflare API token
```

**`03-issuer.yaml`**
```yaml
email: {{ hello@example.com }}
# Replace with your email address for Let's Encrypt notifications
```

**`04-certificate.yaml`**
```yaml
dnsNames:
  - {{ "*.example.com" }}
# Replace with your actual domain (e.g., "*.yourdomain.com")
```

**`07-statefulset.yaml`**
```yaml
env:
  - name: NEO4J_AUTH
    value: "neo4j/temppassword"
# Change to a secure password!
```

## Installation

Deploy the resources in order:

### Step 1: Create Namespace

```bash
kubectl apply -f 01-namespace.yaml
```

### Step 2: Create Cloudflare API Token Secret

```bash
# Option A: Apply the manifest (after updating the placeholder)
kubectl apply -f 02-cloudflare-api-token.yaml

# Option B: Create directly from command line
kubectl create secret generic cloudflare-api-token \
  --from-literal=api-token=<YOUR_CLOUDFLARE_API_TOKEN> \
  --namespace dozerdb-ns
```

### Step 3: Create Certificate Issuer

```bash
kubectl apply -f 03-issuer.yaml
```

### Step 4: Request SSL Certificate

```bash
kubectl apply -f 04-certificate.yaml
```

Verify the certificate is issued:

```bash
kubectl get certificate -n dozerdb-ns
kubectl describe certificate dozerdb-cert -n dozerdb-ns
```

### Step 5: Create Services

```bash
kubectl apply -f 05-headless-service.yaml
kubectl apply -f 06-loadbalancer.yaml
```

### Step 6: Create HTTP Redirect ConfigMap

> **Important:** Before applying `08-http-redirect.yaml`, edit the nginx ConfigMap and replace all instances of `db.example.com` with your actual domain name.  
> This ensures HTTP requests are properly redirected to your HTTPS endpoint.

```bash
kubectl apply -f 08-http-redirect.yaml
```

This creates the nginx configuration for the HTTP to HTTPS redirect sidecar.

### Step 7: Deploy DozerDB StatefulSet

```bash
kubectl apply -f 07-statefulset.yaml
```

This deploys DozerDB with an HTTP redirect sidecar in the same pod:
- Main container: DozerDB (HTTPS on 7474, Bolt on 7687)
- Sidecar container: nginx:alpine (HTTP redirect on port 8080)
- Both share the same LoadBalancer (cost-effective!)

## Verification

### Check Pod Status

```bash
kubectl get pods -n dozerdb-ns
```

Wait until the pod status is `Running`.

### Check Logs

```bash
kubectl logs -n dozerdb-ns dozerdb-0 --follow
```

### Get Load Balancer IP

```bash
kubectl get svc -n dozerdb-ns dozerdb-service
```

Note the `EXTERNAL-IP` value. This **single LoadBalancer** handles all traffic:
- Port 80 (HTTP) → redirects to HTTPS
- Port 443 (HTTPS) → DozerDB Neo4j Browser
- Port 7687 (Bolt) → DozerDB database connections

### Update DNS Records

Point your domain to the load balancer IP:

```
A     db.example.com    <EXTERNAL-IP>
```

## Access DozerDB

### Neo4j Browser (HTTPS)

Open your browser and navigate to:
```
https://db.example.com
```

**HTTP automatically redirects to HTTPS:**
```
http://db.example.com  →  https://db.example.com
```

**Credentials:**
- Username: `neo4j`
- Password: `temppassword` (or your custom password)

### Bolt Connection (Cypher Shell or Application)

```bash
cypher-shell -a neo4j+s://db.example.com:7687 -u neo4j -p temppassword
```

**Connection string for applications:**
```
neo4j+s://db.example.com:7687
```

## Architecture

### Services

| Service | Type | Ports | Purpose |
|---------|------|-------|---------|
| dozerdb-headless | ClusterIP (None) | 7474, 7687 | StatefulSet pod identity |
| dozerdb-service | LoadBalancer | 80→8080, 443→7474, 7687→7687 | **Single LB for all traffic** |

### Ports

- **80**: HTTP on port 80 (LoadBalancer) → mapped to nginx sidecar port 8080 → redirects to HTTPS
- **443/7474**: HTTPS (Neo4j Browser and HTTP API)
- **7687**: Bolt protocol (database connections)

### HTTP Redirect Architecture (Cost-Optimized!)

Uses a **sidecar pattern** to minimize costs:
- nginx:alpine runs as a sidecar in the DozerDB pod
- Listens on port 8080 (mapped from LoadBalancer port 80)
- Issues 301 redirect to HTTPS
- **Only ONE LoadBalancer** for all traffic (saves money!)
- Minimal resources: 32Mi memory, 50m CPU

### Storage

- **Volume type**: Hetzner Cloud Volume
- **Storage class**: `hcloud-volumes`
- **Size**: 10Gi (bare minimum)
- **Access mode**: ReadWriteOnce

### Resources

**Bare minimum allocation:**
- CPU Request: 250m (0.25 cores)
- CPU Limit: 500m (0.5 cores)
- Memory Request: 512Mi
- Memory Limit: 1Gi

**Note**: These are minimal settings for development/testing. For production workloads, consider increasing resources based on your data size and query complexity.

## Management

### Scale Replicas

**Note**: DozerDB currently runs as a single instance. For clustering, additional configuration is required.

### Backup Data

```bash
# Create a backup using kubectl cp
kubectl cp dozerdb-ns/dozerdb-0:/data ./backup-$(date +%Y%m%d)
```

### Update Password

Edit the StatefulSet:

```bash
kubectl edit statefulset dozerdb -n dozerdb-ns
```

Change the `NEO4J_AUTH` environment variable, then restart the pod:

```bash
kubectl delete pod dozerdb-0 -n dozerdb-ns
```

### View Configuration

```bash
kubectl describe statefulset dozerdb -n dozerdb-ns
```

### Update Resource Limits

Edit `07-statefulset.yaml` and reapply:

```bash
kubectl apply -f 07-statefulset.yaml
```

## Troubleshooting

### Certificate Not Issued

Check cert-manager logs:

```bash
kubectl logs -n cert-manager -l app=cert-manager
```

Check certificate status:

```bash
kubectl describe certificate dozerdb-cert -n dozerdb-ns
kubectl get certificaterequest -n dozerdb-ns
```

### Pod Not Starting

Check pod events:

```bash
kubectl describe pod dozerdb-0 -n dozerdb-ns
```

Check logs:

```bash
kubectl logs dozerdb-0 -n dozerdb-ns
```

### Storage Issues

Verify PVC is bound:

```bash
kubectl get pvc -n dozerdb-ns
```

Check storage class:

```bash
kubectl get storageclass hcloud-volumes
```

### Connection Refused

Ensure the load balancer is provisioned:

```bash
kubectl get svc dozerdb-service -n dozerdb-ns -o wide
```

Test SSL certificate:

```bash
openssl s_client -connect db.example.com:443 -servername db.example.com
```

## Uninstallation

Remove resources in reverse order:

```bash
kubectl delete -f 07-statefulset.yaml
kubectl delete -f 08-http-redirect.yaml
kubectl delete -f 06-loadbalancer.yaml
kubectl delete -f 05-headless-service.yaml
kubectl delete -f 04-certificate.yaml
kubectl delete -f 03-issuer.yaml
kubectl delete -f 02-cloudflare-api-token.yaml
kubectl delete -f 01-namespace.yaml
```

**Warning**: This will delete all data in the persistent volume!

To preserve data, backup before uninstalling:

```bash
kubectl cp dozerdb-ns/dozerdb-0:/data ./backup-final
```

## Security Considerations

1. **Change default password** - Never use `temppassword` in production
2. **Restrict access** - Use NetworkPolicies to limit pod-to-pod communication
3. **Rotate API tokens** - Regularly rotate your Cloudflare API token
4. **Enable auth plugins** - Configure Neo4j authentication plugins if needed
5. **Monitor logs** - Set up log aggregation for security auditing

## Resources

- [DozerDB Documentation](https://graphstack.io/)
- [Neo4j Documentation](https://neo4j.com/docs/)
- [Cert-Manager Documentation](https://cert-manager.io/docs/)
- [Hetzner Cloud Volumes](https://docs.hetzner.com/cloud/volumes/overview/)
