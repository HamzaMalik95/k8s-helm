# NGINX Ingress Controller Helm Chart

This chart deploys the NGINX Ingress Controller for managing HTTP/HTTPS ingress traffic.

## Overview

This chart replaces the manual deployment of:
```bash
kubectl apply -f live/All-Clusters-BASE-REQUIRED/nginx-ingress-controller/1.11.3/
```

## Components Included

- **NGINX Ingress Main Controller**: Primary ingress controller deployment
- **NGINX Ingress External Controller**: External-facing ingress controller
- **TLS Secrets**: SSL/TLS certificates for ingress
- **Prometheus RBAC**: Monitoring integration
- **Health Check Service**: Load balancer health checks
- **ConfigMaps**: NGINX configuration
- **RBAC**: ServiceAccounts, ClusterRoles, ClusterRoleBindings

## Installation

### Prerequisites

- Kubernetes cluster
- kubectl configured with appropriate context
- Helm 3.x installed
- Load balancer support (cloud provider or MetalLB for on-prem)

### Deploy to a Cluster

```bash
# Set your kubeconfig context
kubectl config use-context <your-cluster-context>

# Install/upgrade the chart
helm upgrade --install nginx-ingress ./helm-charts/nginx-ingress
```

## Usage Examples

### Deploy to Different Clusters

```bash
# Deploy to dev cluster
kubectl config use-context cadev
helm upgrade --install nginx-ingress ./helm-charts/nginx-ingress

# Deploy to prod cluster
kubectl config use-context caprod
helm upgrade --install nginx-ingress ./helm-charts/nginx-ingress

# Deploy to Azure AKS
kubectl config use-context aks-aks-prd-westus2-001
helm upgrade --install nginx-ingress ./helm-charts/nginx-ingress
```

## Verification

```bash
# Check ingress controller pods
kubectl get pods -n ingress-nginx

# Check ingress controller services
kubectl get svc -n ingress-nginx

# Check ingress controller logs
kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller

# List all ingress resources
kubectl get ingress -A
```

## Features

- **Dual Controllers**: Main and external ingress controllers for traffic segregation
- **SSL/TLS**: Built-in certificate management
- **Prometheus Integration**: Metrics export for monitoring
- **High Availability**: Multiple replicas with pod disruption budget
- **ConfigMap-based Configuration**: Easy NGINX tuning

## Troubleshooting

### Ingress not working
Check controller logs:
```bash
kubectl logs -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx
```

### Check ingress class
```bash
kubectl get ingressclass
```

### Verify service endpoints
```bash
kubectl get endpoints -n ingress-nginx
```

### Test ingress connectivity
```bash
# Get external IP
kubectl get svc -n ingress-nginx

# Test HTTP
curl http://<external-ip>

# Check specific ingress
kubectl describe ingress <ingress-name> -n <namespace>
```

## Architecture

### Main vs External Controllers

- **Main Controller**: Internal ingress for cluster-to-cluster traffic
- **External Controller**: External-facing ingress for public traffic

Both controllers can be configured independently via their respective ConfigMaps.

### TLS Certificates

TLS secrets are included in `ingress-secret.yaml`. Update this file with your own certificates:

```bash
# Create TLS secret
kubectl create secret tls <secret-name> \
  --cert=path/to/cert.crt \
  --key=path/to/key.key \
  -n ingress-nginx
```

## Upgrading

### From Previous Versions

This chart uses NGINX Ingress Controller 1.11.3. To upgrade from older versions:

```bash
# Check current version
kubectl get deployment -n ingress-nginx -o jsonpath='{.items[*].spec.template.spec.containers[0].image}'

# Upgrade with Helm
helm upgrade nginx-ingress ./helm-charts/nginx-ingress

# Monitor rollout
kubectl rollout status deployment -n ingress-nginx
```

## Uninstallation

```bash
helm uninstall nginx-ingress
```

**Warning**: This will remove all ingress controllers, breaking ingress traffic for all applications.

## Behavior Preservation

This chart maintains **identical behavior** to the original `kubectl apply -f` workflow:
- All resource specifications match original YAML files (version 1.11.3)
- No modifications to controller configuration, RBAC, or networking
- TLS secrets preserved as-is
- Works across all cluster types (on-prem, AWS, Azure)

## GitOps Integration

Example ArgoCD Application:
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: nginx-ingress
  namespace: argocd
spec:
  project: default
  source:
    repoURL: <your-repo-url>
    targetRevision: HEAD
    path: helm-charts/nginx-ingress
  destination:
    server: https://kubernetes.default.svc
    namespace: ingress-nginx
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

## Additional Resources

- NGINX Ingress Documentation: https://kubernetes.github.io/ingress-nginx/
- Version 1.11.3 Release Notes: https://github.com/kubernetes/ingress-nginx/releases/tag/controller-v1.11.3
