# Hetzner Cloud CSI Driver

Persistent volume support for Kubernetes clusters running on Hetzner Cloud.

## Installation

### Step 1: Add Helm Repository

```bash
helm repo add hcloud https://charts.hetzner.cloud
helm repo update
```

### Step 2: Install the CSI Driver

```bash
helm upgrade --install hcloud-csi hcloud/hcloud-csi \
  --namespace kube-system \
  --values hetzner-csi.yaml
```

### Step 3: Verify Installation

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
  name: my-pvc
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: hcloud-volumes
  resources:
    requests:
      storage: 10Gi
```

## Configuration

The CSI driver is configured via `hetzner-csi.yaml`. Key settings:

- **Controller replicas**: 2 (for high availability)
- **Priority class**: system-node-critical
- **Node selector**: Hetzner nodes only
- **Anti-affinity**: Distributes controller replicas across nodes

## Prerequisites

- Kubernetes cluster running on Hetzner Cloud
- Valid Hetzner Cloud API token stored in a secret
- Nodes labeled with `cfke.io/provider: hetzner`
