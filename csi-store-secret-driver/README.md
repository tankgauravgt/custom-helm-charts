# Azure Key Vault Secrets in Kubernetes

Access Azure Key Vault secrets securely using **Workload Identity** + **CSI Driver**—zero hardcoded credentials.

**The flow:** Azure trusts your cluster → Your pod's identity authenticates → Secrets mount as files → Your app reads them.

## Step 1: Azure Setup

```bash
export RESOURCE_GROUP="myapp-rg"
export IDENTITY_NAME="myapp-identity"
export SUBSCRIPTION_ID="12345678-1234-1234-1234-123456789012"
export KEY_VAULT_NAME="myapp-vault"
export REGION="eastus"

# Create the identity
az identity create --name $IDENTITY_NAME -g $RESOURCE_GROUP --location $REGION

# Save the credentials (you'll need these)
export IDENTITY_CLIENT_ID=$(az identity show --name $IDENTITY_NAME -g $RESOURCE_GROUP --query "clientId" -o tsv)
export IDENTITY_PRINCIPAL_ID=$(az identity show --name $IDENTITY_NAME -g $RESOURCE_GROUP --query "principalId" -o tsv)
export IDENTITY_TENANT_ID=$(az identity show --name $IDENTITY_NAME -g $RESOURCE_GROUP --query "tenantId" -o tsv)

# Grant it access to your vault
az role assignment create \
  --role "Key Vault Secrets User" \
  --assignee $IDENTITY_PRINCIPAL_ID \
  --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.KeyVault/vaults/$KEY_VAULT_NAME"
```

## Step 2: Install CSI Driver

```bash
helm repo add csi-secrets-store-provider-azure https://azure.github.io/secrets-store-csi-driver-provider-azure/charts
helm repo update
helm install csi-secrets-store-provider-azure csi-secrets-store-provider-azure/csi-secrets-store-provider-azure \
  --namespace secrets-store-csi --create-namespace
```

## Step 3: Create Namespace & ServiceAccount

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: myapp-ns
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: myapp-sa
  namespace: myapp-ns
```
`kubectl apply -f ns-and-sa.yaml`

Get your Cloudfleet OIDC issuer URL from your dashboard:
```
https://api.cloudfleet.ai/v1/clusters/<YOUR_CLUSTER_ID>
```

## Step 4: Connect Azure to Kubernetes

Link your Managed Identity to your ServiceAccount using OIDC federation:

```bash
export OIDC_ISSUER_URL="https://api.cloudfleet.ai/v1/clusters/abc123xyz"
export K8S_NAMESPACE="myapp-ns"
export K8S_SERVICE_ACCOUNT="myapp-sa"

az identity federated-credential create \
  --name "cloudfleet-federation" \
  --identity-name myapp-identity \
  --resource-group myapp-rg \
  --issuer $OIDC_ISSUER_URL \
  --subject "system:serviceaccount:$K8S_NAMESPACE:$K8S_SERVICE_ACCOUNT"
```

## Step 5: Deploy Your App

**Create SecretProviderClass** (tells the driver what secrets to fetch):

```yaml
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: azure-keyvault-provider
  namespace: myapp-ns
spec:
  provider: azure
  parameters:
    useWorkloadIdentity: "true"
    keyvaultName: "myapp-vault"
    tenantId: "87654321-4321-4321-4321-210987654321"
    clientID: "11111111-2222-3333-4444-555555555555"
    objects: |
      array:
        - |
          objectName: DatabasePassword
          objectType: secret
          fileName: db-password
        - |
          objectName: ApiToken
          objectType: secret
          fileName: api-token
```
`kubectl apply -f spc.yaml`

**Deploy your application** (mounts secrets as files):

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
  namespace: myapp-ns
spec:
  replicas: 1
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
    spec:
      serviceAccountName: myapp-sa
      containers:
        - name: myapp
          image: myapp:latest
          volumeMounts:
            - name: secrets-volume
              mountPath: "/mnt/secrets"
              readOnly: true
      volumes:
        - name: secrets-volume
          csi:
            driver: secrets-store.csi.k8s.io
            readOnly: true
            volumeAttributes:
              secretProviderClass: "azure-keyvault-provider"
```
`kubectl apply -f deployment.yaml`

Your secrets are now available as files:
- `/mnt/secrets/db-password`
- `/mnt/secrets/api-token`
