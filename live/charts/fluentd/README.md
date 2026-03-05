# Fluentd Helm Chart

This chart deploys Fluentd as a DaemonSet for log aggregation and shipping to Splunk.

## Overview

This chart replaces the manual deployment of:
```bash
kubectl apply -f live/All-Clusters-BASE-REQUIRED/fluentd/
kubectl apply -f live/All-Clusters-BASE-REQUIRED/fluentd/clustername/<cluster-name>/
```

## Components Included (Deployed in Order)

1. **Namespace**: fluentd namespace with LimitRange and NetworkPolicy
2. **RBAC**: ServiceAccount, ClusterRole, ClusterRoleBinding for log access
3. **PodSecurityPolicy**: Security policy for Fluentd pods
4. **Secret**: Splunk HEC tokens (must be updated before deployment)
5. **ConfigMap**: Fluentd configuration
6. **DaemonSet**: Fluentd pods running on every node
7. **Cluster Name ConfigMap**: Cluster-specific identifier for Splunk

## Installation

### Prerequisites

- Kubernetes cluster
- kubectl configured with appropriate context
- Helm 3.x installed
- Splunk HEC endpoint configured
- Network egress to Splunk allowed

### Configure Splunk HEC Tokens

Before deploying, update the Splunk HEC tokens in:
```
helm-charts/fluentd/templates/4-secret-splunk-hec-tokens.yaml
```

Replace the placeholder tokens with actual Splunk HEC tokens (base64 encoded).

### Deploy to a Cluster

**IMPORTANT**: The `clusterName` parameter is **REQUIRED**.

```bash
# Set your kubeconfig context
kubectl config use-context <your-cluster-context>

# Install/upgrade with cluster name
helm upgrade --install fluentd ./helm-charts/fluentd \
  --set clusterName=<your-cluster-name>
```

## Usage Examples

### Deploy to Different Clusters

```bash
# Deploy to cadev cluster
kubectl config use-context cadev
helm upgrade --install fluentd ./helm-charts/fluentd \
  --set clusterName=cadev

# Deploy to caprod cluster
kubectl config use-context caprod
helm upgrade --install fluentd ./helm-charts/fluentd \
  --set clusterName=caprod

# Deploy to Azure AKS dev
kubectl config use-context aks-aks-dev-westus2-001
helm upgrade --install fluentd ./helm-charts/fluentd \
  --set clusterName=aks-aks-dev-westus2-001

# Deploy to Azure AKS prod
kubectl config use-context aks-aks-prd-westus2-001
helm upgrade --install fluentd ./helm-charts/fluentd \
  --set clusterName=aks-aks-prd-westus2-001

# Deploy to azprod
kubectl config use-context azprod
helm upgrade --install fluentd ./helm-charts/fluentd \
  --set clusterName=azprod
```

### Using Values File

Create a values file for your cluster:

```yaml
# values-cadev.yaml
clusterName: cadev
```

Deploy:
```bash
helm upgrade --install fluentd ./helm-charts/fluentd -f values-cadev.yaml
```

## Configuration

### Key Values

| Parameter | Description | Required | Default |
|-----------|-------------|----------|---------|
| `clusterName` | Cluster identifier for Splunk logs | **YES** | `""` |

### Cluster Names Reference

| Cluster | clusterName Value |
|---------|-------------------|
| cadev | `cadev` |
| calab | `calab` |
| caprod | `caprod` |
| azprod | `azprod` |
| AKS Dev West US 2 | `aks-aks-dev-westus2-001` |
| AKS Prod East US | `aks-aks-prd-eastus-001` |
| AKS Prod West US 2 | `aks-aks-prd-westus2-001` |

## Verification

```bash
# Check fluentd pods (should be one per node)
kubectl get pods -n fluentd

# Check fluentd logs
kubectl logs -n fluentd -l app=fluentd

# Verify logs are being shipped
kubectl logs -n fluentd -l app=fluentd | grep -i splunk

# Check cluster name ConfigMap
kubectl get configmap clustername -n fluentd -o yaml
```

## How It Works

1. **Log Collection**: Fluentd runs as DaemonSet on every node
2. **Log Parsing**: Fluentd parses container logs using configured patterns
3. **Log Enrichment**: Adds Kubernetes metadata (pod, namespace, labels)
4. **Cluster Tagging**: Tags logs with cluster name from ConfigMap
5. **Log Shipping**: Sends logs to Splunk via HEC (HTTP Event Collector)

## Troubleshooting

### Fluentd pods not starting
Check pod status:
```bash
kubectl describe pods -n fluentd -l app=fluentd
```

### Logs not appearing in Splunk
Check Fluentd logs for errors:
```bash
kubectl logs -n fluentd -l app=fluentd | grep -i error
```

Verify HEC tokens:
```bash
kubectl get secret splunk-hec-tokens -n fluentd -o yaml
```

### Network connectivity issues
Test egress to Splunk:
```bash
kubectl run -it --rm debug --image=curlimages/curl --restart=Never -- \
  curl -k https://<splunk-hec-endpoint>:8088/services/collector/health
```

### High memory usage
Check resource limits:
```bash
kubectl top pods -n fluentd
```

## Deployment Order

The chart automatically deploys resources in the correct order:

1. Namespace (with NetworkPolicy and LimitRange)
2. RBAC (ServiceAccount, ClusterRole, ClusterRoleBinding)
3. PodSecurityPolicy
4. Secret (Splunk HEC tokens)
5. ConfigMap (Fluentd configuration)
6. DaemonSet (Fluentd pods)
7. Cluster Name ConfigMap

Helm ensures this order is maintained during installation and upgrades.

## Updating Splunk HEC Tokens

To update HEC tokens:

1. Edit `templates/4-secret-splunk-hec-tokens.yaml`
2. Update base64-encoded token values
3. Run `helm upgrade`:
```bash
helm upgrade fluentd ./helm-charts/fluentd --set clusterName=<cluster>
```

## Uninstallation

```bash
helm uninstall fluentd
```

**Warning**: This will stop log shipping to Splunk for the entire cluster.

## Behavior Preservation

This chart maintains **identical behavior** to the original `kubectl apply -f` workflow:
- All resources match original YAML files exactly
- Deployment order preserved (numbered files 1-6, then cluster-specific)
- No modifications to Fluentd configuration, RBAC, or DaemonSet specs
- Cluster name ConfigMap templated for easy deployment across clusters
- Works across all cluster types (on-prem, AWS, Azure)

## GitOps Integration

Example ArgoCD Application:
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: fluentd
  namespace: argocd
spec:
  project: default
  source:
    repoURL: <your-repo-url>
    targetRevision: HEAD
    path: helm-charts/fluentd
    helm:
      values: |
        clusterName: cadev  # Set per cluster
  destination:
    server: https://kubernetes.default.svc
    namespace: fluentd
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

## Security Notes

- **Splunk HEC Tokens**: Stored as Kubernetes secrets (base64 encoded)
- **Network Policy**: Restricts traffic to/from Fluentd namespace
- **PodSecurityPolicy**: Enforces security constraints on Fluentd pods
- **RBAC**: Fluentd only has read access to pod logs and metadata

Update HEC tokens regularly and use separate tokens per cluster for security isolation.
