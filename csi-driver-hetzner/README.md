# Hetzner Cloud CSI Driver

Persistent volume support for Kubernetes clusters running on Hetzner Cloud.

## Prerequisites

- Kubernetes cluster running on Hetzner Cloud
- Azure Key Vault with Hetzner Cloud API token stored as a secret
- Azure Workload Identity configured for the cluster
- Azure Service Principal with access to Key Vault

> [!WARNING]
> The storage will be only assigned to the nodes running on Hetzner Cloud.

## Installation

This setup uses Azure Key Vault with the Secrets Store CSI Driver to securely fetch the Hetzner Cloud API token.

### Step 1: Create Service Account for Azure Workload Identity

Apply the service account configuration:

```bash
kubectl apply -f 01-sa-hetzner-fetcher.yaml
```

**Before applying**, update the following in `01-sa-hetzner-fetcher.yaml`:
- `<AZURE_CLIENT_ID>`: Your Azure Managed Identity client ID

### Step 2: Configure Secret Provider Class

Apply the Secret Provider Class:

```bash
kubectl apply -f 02-spc-hetzner.yaml
```

**Before applying**, update the following in `02-spc-hetzner.yaml`:
- `<AZURE_CLIENT_ID>`: Your Azure Managed Identity client ID
- `<KEYVAULT_NAME>`: Your Azure Key Vault name
- `<AZURE_TENANT_ID>`: Your Azure tenant ID
- `<keyvault-secret-name>`: The name of the secret in Key Vault containing the Hetzner API token

This will create a SecretProviderClass that fetches the Hetzner token from Azure Key Vault and creates a Kubernetes secret named `hetzner-csi-secret` in the `kube-system` namespace.

### Step 3: Deploy Trigger Pod

Deploy a pod to trigger the secret synchronization:

```bash
kubectl apply -f 03-trigger-pod.yaml
```

This pod mounts the secrets-store volume, which triggers the creation of the `hetzner-csi-secret` Kubernetes secret.

Verify the secret was created:

```bash
kubectl get secret hetzner-csi-secret -n kube-system
```

### Step 4: Add Helm Repository

```bash
helm repo add hcloud https://charts.hetzner.cloud
helm repo update
```

### Step 5: Install the Hetzner CSI Driver

Install using the configuration file that references the existing secret:

```bash
helm upgrade --install hcloud-csi hcloud/hcloud-csi \
  --namespace kube-system \
  --values 04-hetzner-csi.yaml
```

The `04-hetzner-csi.yaml` file configures the CSI driver to use the existing `hetzner-csi-secret` created by the Secrets Store CSI Driver.

### Step 6: Verify Installation

Check that the CSI driver pods are running:

```bash
kubectl get pods -n kube-system -l app.kubernetes.io/name=hcloud-csi
```

Verify the storage class is available:

```bash
kubectl get storageclass hcloud-volumes
```

## Usage

Create a PersistentVolumeClaim using the `hcloud-volumes` storage class:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: test-pvc
  namespace: default
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
  volumeMode: Filesystem
```

See `example.yaml` for a complete example including a pod that uses the PVC.

## Testing

To test the setup, apply the example configuration:

```bash
kubectl apply -f example.yaml
```

This creates:
- A 10Gi PersistentVolumeClaim named `test-pvc`
- A test pod that mounts the PVC at `/mnt/test-pvc`

Verify the PVC is bound:

```bash
kubectl get pvc test-pvc -n default
```

Check the test pod is running:

```bash
kubectl get pod test-pod -n default
```

## Configuration Files

- **01-sa-hetzner-fetcher.yaml**: Service Account with Azure Workload Identity annotation
- **02-spc-hetzner.yaml**: SecretProviderClass that fetches Hetzner token from Azure Key Vault
- **03-trigger-pod.yaml**: Trigger pod to create the Kubernetes secret from Key Vault
- **04-hetzner-csi.yaml**: Helm values file referencing the existing secret
- **example.yaml**: Example PVC and pod for testing

## Architecture

This setup follows a secure pattern:
1. Hetzner API token is stored in Azure Key Vault
2. Azure Workload Identity authenticates the service account
3. Secrets Store CSI Driver fetches the token and creates a Kubernetes secret
4. Hetzner CSI Driver uses the Kubernetes secret to authenticate with Hetzner Cloud

## Troubleshooting

Check the trigger pod logs:
```bash
kubectl logs hetzner-secret-trigger -n kube-system
```

Verify the secret exists:
```bash
kubectl describe secret hetzner-csi-secret -n kube-system
```

Check CSI driver logs:
```bash
kubectl logs -n kube-system -l app.kubernetes.io/name=hcloud-csi
```
