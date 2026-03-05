# CoreDNS Helm Chart

This chart deploys CoreDNS, the DNS server for the Kubernetes cluster.

## Overview

This chart replaces the manual deployment of:
```bash
kubectl apply -f live/All-Clusters-BASE-REQUIRED/coredns/
```

## Components Included

- **CoreDNS Deployment**: 5 replicas with pod anti-affinity
- **CoreDNS ConfigMap**: Corefile configuration with optional logging

## Installation

### Prerequisites

- Kubernetes cluster with existing CoreDNS Service and ServiceAccount
- kubectl configured with appropriate context
- Helm 3.x installed

### Deploy to a Cluster

```bash
# Set your kubeconfig context
kubectl config use-context <your-cluster-context>

# Install/upgrade the chart (default: logging disabled)
helm upgrade --install coredns ./helm-charts/coredns

# For calab cluster or debugging (enable logging)
helm upgrade --install coredns ./helm-charts/coredns \
  --set coredns.enableLogging=true
```

## Configuration

### Key Values

| Parameter | Description | Default |
|-----------|-------------|---------|
| `coredns.replicas` | Number of CoreDNS pods | `5` |
| `coredns.image.repository` | CoreDNS image repository | `registry.k8s.io/coredns/coredns` |
| `coredns.image.tag` | CoreDNS image tag | `v1.10.1` |
| `coredns.enableLogging` | Enable query logging | `false` |
| `coredns.resources.limits.memory` | Memory limit | `350Mi` |
| `coredns.resources.requests.cpu` | CPU request | `500m` |
| `coredns.resources.requests.memory` | Memory request | `170Mi` |

### Cluster-Specific Configurations

**Standard clusters (cadev, caprod, azprod, prod):**
```bash
helm upgrade --install coredns ./helm-charts/coredns
```

**Lab cluster (calab) with logging:**
```bash
helm upgrade --install coredns ./helm-charts/coredns \
  --set coredns.enableLogging=true
```

## Usage Examples

### Deploy to Different Clusters

```bash
# Deploy to cadev (no logging)
kubectl config use-context cadev
helm upgrade --install coredns ./helm-charts/coredns

# Deploy to calab (with logging)
kubectl config use-context calab
helm upgrade --install coredns ./helm-charts/coredns \
  --set coredns.enableLogging=true

# Deploy to Azure AKS
kubectl config use-context aks-aks-prd-westus2-001
helm upgrade --install coredns ./helm-charts/coredns
```

### Custom Configuration

Create a values file for custom settings:

```yaml
# values-custom.yaml
coredns:
  replicas: 3
  enableLogging: true
  resources:
    limits:
      memory: 500Mi
    requests:
      cpu: 250m
      memory: 128Mi
```

Deploy with custom values:
```bash
helm upgrade --install coredns ./helm-charts/coredns -f values-custom.yaml
```

## Verification

```bash
# Check CoreDNS pods
kubectl get pods -n kube-system -l k8s-app=kube-dns

# Check CoreDNS logs
kubectl logs -n kube-system -l k8s-app=kube-dns

# Test DNS resolution
kubectl run -it --rm debug --image=busybox --restart=Never -- nslookup kubernetes.default
```

## Important Notes

### Existing CoreDNS
- This chart is safe to deploy on clusters where CoreDNS already exists
- It will update the Deployment and ConfigMap
- It does NOT manage the CoreDNS Service or ServiceAccount (assumes they exist)

### Rolling Updates
- Updates trigger a rolling restart of CoreDNS pods
- DNS service remains available during updates (maxUnavailable: 1)

### High Availability
- 5 replicas with pod anti-affinity for distribution across nodes
- Priority class: system-cluster-critical

## Troubleshooting

### CoreDNS pods not starting
Check if the coredns ServiceAccount exists:
```bash
kubectl get serviceaccount coredns -n kube-system
```

### DNS resolution issues
Enable logging temporarily:
```bash
helm upgrade coredns ./helm-charts/coredns --set coredns.enableLogging=true
kubectl logs -n kube-system -l k8s-app=kube-dns -f
```

## Uninstallation

```bash
helm uninstall coredns
```

**Warning**: This will remove CoreDNS from your cluster, breaking DNS resolution. Only uninstall if you have an alternative DNS solution.

## Behavior Preservation

This chart maintains **identical behavior** to the original `kubectl apply -f` workflow:
- All resource specifications match original YAML files
- No modifications to container args, probes, or security contexts
- ConfigMap Corefile matches original (with optional logging flag)
- Works across all cluster types (on-prem, AWS, Azure)

## GitOps Integration

Example ArgoCD Application:
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: coredns
  namespace: argocd
spec:
  project: default
  source:
    repoURL: <your-repo-url>
    targetRevision: HEAD
    path: helm-charts/coredns
    helm:
      values: |
        coredns:
          enableLogging: false  # Set to true for calab
  destination:
    server: https://kubernetes.default.svc
    namespace: kube-system
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```
