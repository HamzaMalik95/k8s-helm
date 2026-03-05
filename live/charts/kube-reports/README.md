# Kube Reports Helm Chart

This chart deploys Kube Reports for live Kubernetes resource reporting and visualization.

## Overview

This chart replaces the manual deployment of:
```bash
kubectl apply -f live/All-Clusters-BASE-REQUIRED/kube-reports/
kubectl apply -f live/All-Clusters-BASE-REQUIRED/kube-reports/<cluster-name>/
```

## Components Included

- **Kube Reports Deployment**: Web application for resource reporting
- **Service**: ClusterIP service for kube-reports
- **NetworkPolicy**: Network policy for nginx-ingress access
- **RBAC**: ServiceAccount, ClusterRole, ClusterRoleBinding for read access
- **Optional Ingress**: Cluster-specific ingress configuration

## Installation

### Prerequisites

- Kubernetes cluster
- kubectl configured with appropriate context
- Helm 3.x installed
- NGINX Ingress Controller (if using ingress)
- Namespace must exist or will be created by deployment

### Deploy Without Ingress

```bash
# Set your kubeconfig context
kubectl config use-context <your-cluster-context>

# Install/upgrade (no ingress)
helm upgrade --install kube-reports ./helm-charts/kube-reports \
  --set namespace=<target-namespace> \
  --create-namespace
```

### Deploy With Ingress

```bash
# For cadev cluster
helm upgrade --install kube-reports ./helm-charts/kube-reports \
  --set namespace=itsystems-dev \
  --set ingress.enabled=true \
  --set ingress.host=k8cadev.medimpact.com \
  --create-namespace

# For caprod cluster
helm upgrade --install kube-reports ./helm-charts/kube-reports \
  --set namespace=itsystems-prod \
  --set ingress.enabled=true \
  --set ingress.host=k8caprod.medimpact.com \
  --create-namespace

# For azprod cluster
helm upgrade --install kube-reports ./helm-charts/kube-reports \
  --set namespace=itsystems-lab \
  --set ingress.enabled=true \
  --set ingress.host=k8azprod.medimpact.com \
  --create-namespace

# For calab cluster
helm upgrade --install kube-reports ./helm-charts/kube-reports \
  --set namespace=itsystems-dev \
  --set ingress.enabled=true \
  --set ingress.host=k8calab.medimpact.com \
  --create-namespace
```

## Configuration

### Key Values

| Parameter | Description | Default |
|-----------|-------------|---------|
| `namespace` | Namespace for deployment | `itsystems-dev` |
| `rbac.create` | Create RBAC resources | `true` |
| `rbac.serviceAccountName` | Service account name | `kube-reports-serviceaccount` |
| `ingress.enabled` | Enable ingress creation | `false` |
| `ingress.host` | Hostname for ingress | `""` |
| `ingress.path` | Path prefix | `/report` |
| `ingress.className` | Ingress class name | `nginx` |

### Cluster-Specific Configurations

| Cluster | Namespace | Hostname |
|---------|-----------|----------|
| cadev | itsystems-dev | k8cadev.medimpact.com |
| calab | itsystems-dev | k8calab.medimpact.com |
| caprod | itsystems-prod | k8caprod.medimpact.com |
| azprod | itsystems-lab | k8azprod.medimpact.com |

## Usage Examples

### Using Values File

Create a values file for your cluster:

```yaml
# values-cadev.yaml
namespace: itsystems-dev
ingress:
  enabled: true
  host: k8cadev.medimpact.com
```

Deploy:
```bash
helm upgrade --install kube-reports ./helm-charts/kube-reports \
  -f values-cadev.yaml \
  --create-namespace
```

### Without Ingress (kubectl port-forward)

```bash
# Install without ingress
helm upgrade --install kube-reports ./helm-charts/kube-reports \
  --set namespace=itsystems-dev \
  --create-namespace

# Access via port-forward
kubectl port-forward svc/kube-reports 8080:8080 -n itsystems-dev

# Open browser to http://localhost:8080
```

## Accessing Kube Reports

### Via Ingress

Once deployed with ingress enabled, access kube-reports at:
```
https://<your-ingress-host>/report/
```

For example:
- cadev: https://k8cadev.medimpact.com/report/
- caprod: https://k8caprod.medimpact.com/report/

### Features

Kube Reports provides live views of:
- Nodes and resource utilization
- Namespaces and quotas
- Deployments and replica status
- DaemonSets
- Pods and container status
- Services and endpoints
- Ingresses
- Network policies
- Persistent volumes and claims
- Resource quotas and limit ranges
- RBAC (roles, rolebindings, service accounts)

## Verification

```bash
# Check kube-reports pods
kubectl get pods -n <namespace> -l app=kube-reports

# Check kube-reports service
kubectl get svc -n <namespace> kube-reports

# Check ingress (if enabled)
kubectl get ingress -n <namespace> kube-reports

# Check RBAC
kubectl get clusterrole kube-reports-clusterrole
kubectl get clusterrolebinding kube-reports-clusterrole-binding

# Test access (via port-forward)
kubectl port-forward svc/kube-reports 8080:8080 -n <namespace>
curl http://localhost:8080
```

## Troubleshooting

### Application not starting
Check pod logs:
```bash
kubectl logs -n <namespace> -l app=kube-reports
```

### RBAC permission errors
Verify ClusterRole and ClusterRoleBinding:
```bash
kubectl describe clusterrole kube-reports-clusterrole
kubectl describe clusterrolebinding kube-reports-clusterrole-binding
```

### Ingress not working
Check ingress status:
```bash
kubectl describe ingress kube-reports -n <namespace>
```

Check NGINX ingress logs:
```bash
kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller
```

## Uninstallation

```bash
helm uninstall kube-reports

# Optional: Clean up namespace if empty
kubectl delete namespace <namespace>

# Clean up RBAC (if not managed by Helm)
kubectl delete clusterrole kube-reports-clusterrole
kubectl delete clusterrolebinding kube-reports-clusterrole-binding
```

## Behavior Preservation

This chart maintains **identical behavior** to the original `kubectl apply -f` workflow:
- All resource specifications match original YAML files
- Deployment, service, and network policy unchanged
- RBAC permissions identical (read-only cluster access)
- Ingress configuration matches cluster-specific files
- Works across all cluster types (on-prem, AWS, Azure)

## GitOps Integration

Example ArgoCD Application:
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: kube-reports
  namespace: argocd
spec:
  project: default
  source:
    repoURL: <your-repo-url>
    targetRevision: HEAD
    path: helm-charts/kube-reports
    helm:
      values: |
        namespace: itsystems-dev  # Set per cluster
        ingress:
          enabled: true
          host: k8cadev.medimpact.com  # Set per cluster
  destination:
    server: https://kubernetes.default.svc
    namespace: itsystems-dev  # Set per cluster
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

## Security Notes

- **Read-Only Access**: Kube Reports has read-only ClusterRole
- **Network Policy**: Restricts ingress traffic to nginx-ingress namespace only
- **No Write Permissions**: Cannot modify cluster resources
- **Service Account**: Dedicated service account with minimal permissions
