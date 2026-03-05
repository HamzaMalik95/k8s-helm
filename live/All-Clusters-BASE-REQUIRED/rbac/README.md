# RBAC Helm Chart

This chart deploys cluster-wide RBAC (Role-Based Access Control) resources including ClusterRoles and ClusterRoleBindings.

## Overview

This chart replaces the manual deployment of:
```bash
kubectl apply -f live/All-Clusters-BASE-REQUIRED/clusterroles/
```

## Components Included

- **cluster-admins**: Binds OIDC groups to cluster-admin role
- **cluster-viewers**: Binds OIDC groups to view role
- **cluster-namespace-viewers**: Namespace-scoped view permissions
- **dashboard-users**: Kubernetes Dashboard access bindings
- **jenkins**: Jenkins service account permissions
- **metrics-reader**: Metrics API read access
- **namespace-admins**: Custom namespace admin role with granular permissions
- **namespace-viewers**: Custom namespace viewer role

## Installation

### Prerequisites

- Kubernetes cluster (on-prem, AWS EKS, or Azure AKS)
- kubectl configured with appropriate context
- Helm 3.x installed

### Deploy to a Cluster

```bash
# Set your kubeconfig context to the target cluster
kubectl config use-context <your-cluster-context>

# Install the chart
helm install rbac ./helm-charts/rbac

# Or upgrade if already installed
helm upgrade --install rbac ./helm-charts/rbac
```

## Usage

### Deploying to Different Clusters

The chart is cluster-agnostic. Simply switch your kubeconfig context:

```bash
# Deploy to dev cluster
kubectl config use-context cadev
helm upgrade --install rbac ./helm-charts/rbac

# Deploy to prod cluster
kubectl config use-context caprod
helm upgrade --install rbac ./helm-charts/rbac

# Deploy to Azure AKS
kubectl config use-context aks-aks-prd-westus2-001
helm upgrade --install rbac ./helm-charts/rbac
```

## Adding New RBAC Resources

To add new ClusterRoles or ClusterRoleBindings:

1. Create a new YAML file in `templates/` directory (e.g., `new-role.yaml`)
2. Run `helm upgrade --install rbac ./helm-charts/rbac`

**No code changes required** - Helm automatically applies all YAML files in templates/.

## Verification

```bash
# Verify ClusterRoles
kubectl get clusterroles | grep -E "(medimpact|oidc)"

# Verify ClusterRoleBindings
kubectl get clusterrolebindings | grep oidc

# Check specific role details
kubectl describe clusterrole medimpact:namespace-admin
```

## Uninstallation

```bash
helm uninstall rbac
```

**Warning**: This will remove all RBAC resources managed by this chart. Ensure you have appropriate cluster access before uninstalling.

## Behavior Preservation

This chart maintains **identical behavior** to the original `kubectl apply -f` workflow:
- All resources are deployed exactly as defined in original YAML files
- No modifications to permissions, labels, or selectors
- Idempotent - safe to run multiple times
- Works across all cluster types (on-prem, AWS, Azure)

## GitOps Integration

This chart is compatible with:
- ArgoCD
- Flux
- Plural

Example ArgoCD Application:
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: rbac
  namespace: argocd
spec:
  project: default
  source:
    repoURL: <your-repo-url>
    targetRevision: HEAD
    path: helm-charts/rbac
  destination:
    server: https://kubernetes.default.svc
    namespace: default
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```
