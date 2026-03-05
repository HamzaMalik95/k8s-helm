# EventRouter Helm Chart

This chart deploys EventRouter for capturing and routing Kubernetes events to logging infrastructure.

## Overview

This chart replaces the manual deployment of:
```bash
kubectl apply -f live/All-Clusters-BASE-REQUIRED/eventrouter/
```

## Components Included

- **EventRouter Deployment/DaemonSet**: Captures cluster events
- **ServiceAccount, ClusterRole, ClusterRoleBinding**: RBAC for event access
- **ConfigMap**: EventRouter configuration

## Installation

### Prerequisites

- Kubernetes cluster
- kubectl configured with appropriate context
- Helm 3.x installed

### Deploy to a Cluster

```bash
# Set your kubeconfig context
kubectl config use-context <your-cluster-context>

# Install/upgrade the chart
helm upgrade --install eventrouter ./helm-charts/eventrouter
```

## Usage Examples

### Deploy to Different Clusters

```bash
# Deploy to dev cluster
kubectl config use-context cadev
helm upgrade --install eventrouter ./helm-charts/eventrouter

# Deploy to prod cluster
kubectl config use-context caprod
helm upgrade --install eventrouter ./helm-charts/eventrouter
```

## How It Works

EventRouter watches for Kubernetes events (pod starts, failures, scheduling issues, etc.) and writes them to stdout. These events are then:

1. Captured by container runtime
2. Collected by Fluentd (deployed separately)
3. Sent to Splunk for centralized logging

## Verification

```bash
# Check eventrouter pod
kubectl get pods -n kube-system -l app=eventrouter

# View events being captured
kubectl logs -n kube-system -l app=eventrouter

# Generate a test event
kubectl run test-pod --image=busybox --command -- sleep 3600
kubectl logs -n kube-system -l app=eventrouter | grep test-pod
```

## Uninstallation

```bash
helm uninstall eventrouter
```

## Behavior Preservation

This chart maintains **identical behavior** to the original `kubectl apply -f` workflow:
- All resource specifications match original YAML files
- No modifications to RBAC or event routing logic
- Works across all cluster types (on-prem, AWS, Azure)

## GitOps Integration

Example ArgoCD Application:
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: eventrouter
  namespace: argocd
spec:
  project: default
  source:
    repoURL: <your-repo-url>
    targetRevision: HEAD
    path: helm-charts/eventrouter
  destination:
    server: https://kubernetes.default.svc
    namespace: kube-system
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```
