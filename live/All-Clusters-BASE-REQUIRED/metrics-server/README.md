# Metrics Server Helm Chart

This chart deploys Metrics Server for Kubernetes cluster metrics collection, enabling Horizontal Pod Autoscaling (HPA) and Vertical Pod Autoscaling (VPA).

## Overview

This chart replaces the manual deployment of:
```bash
kubectl apply -f live/All-Clusters-BASE-REQUIRED/metrics-server/0.7.2/
```

## Components Included

- **Metrics Server Deployment**: High-availability configuration
- **ServiceAccount, ClusterRole, ClusterRoleBinding**: RBAC for metrics collection
- **APIService**: Registers metrics API with Kubernetes API server
- **Service**: Exposes metrics endpoint

## Installation

### Prerequisites

- Kubernetes 1.21+
- kubectl configured with appropriate context
- Helm 3.x installed

### Deploy to a Cluster

```bash
# Set your kubeconfig context
kubectl config use-context <your-cluster-context>

# Install/upgrade the chart
helm upgrade --install metrics-server ./helm-charts/metrics-server
```

## Usage Examples

### Deploy to Different Clusters

```bash
# Deploy to dev cluster
kubectl config use-context cadev
helm upgrade --install metrics-server ./helm-charts/metrics-server

# Deploy to prod cluster
kubectl config use-context caprod
helm upgrade --install metrics-server ./helm-charts/metrics-server

# Deploy to Azure AKS
kubectl config use-context aks-aks-prd-westus2-001
helm upgrade --install metrics-server ./helm-charts/metrics-server
```

## Verification

```bash
# Check metrics-server pod
kubectl get pods -n kube-system -l k8s-app=metrics-server

# Verify metrics API is working
kubectl top nodes
kubectl top pods -A

# Check APIService status
kubectl get apiservice v1beta1.metrics.k8s.io
```

## Features

- **High Availability**: Multiple replicas with pod disruption budget
- **Secure**: TLS certificate management for secure communication
- **Resource Metrics**: CPU and memory metrics for all pods and nodes
- **HPA Support**: Enables Horizontal Pod Autoscaler
- **VPA Support**: Enables Vertical Pod Autoscaler

## Troubleshooting

### Metrics not available
Check metrics-server logs:
```bash
kubectl logs -n kube-system -l k8s-app=metrics-server
```

### kubectl top not working
Verify APIService is available:
```bash
kubectl get apiservice v1beta1.metrics.k8s.io -o yaml
```

## Uninstallation

```bash
helm uninstall metrics-server
```

**Warning**: This will remove metrics collection, breaking HPA and `kubectl top` commands.

## Behavior Preservation

This chart maintains **identical behavior** to the original `kubectl apply -f` workflow:
- All resource specifications match original YAML files
- No modifications to RBAC, API service registration, or deployment specs
- Works across all cluster types (on-prem, AWS, Azure)

## GitOps Integration

Example ArgoCD Application:
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: metrics-server
  namespace: argocd
spec:
  project: default
  source:
    repoURL: <your-repo-url>
    targetRevision: HEAD
    path: helm-charts/metrics-server
  destination:
    server: https://kubernetes.default.svc
    namespace: kube-system
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```
