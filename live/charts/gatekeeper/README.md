# Gatekeeper Helm Chart

This chart deploys OPA Gatekeeper for Kubernetes policy enforcement and admission control.

## Overview

This chart replaces the manual deployment of:
```bash
kubectl apply -f live/All-Clusters-BASE-REQUIRED/gatekeeper/3.17.0/
kubectl apply -f live/All-Clusters-BASE-REQUIRED/gatekeeper/policies/
```

## Components Included

- **Gatekeeper CRDs**: Custom Resource Definitions for constraints, templates, mutations
- **Gatekeeper Controller**: Main admission controller
- **Gatekeeper Audit**: Periodic auditing of existing resources
- **Mutation Policies**: Default mutation assignments
- **ValidatingWebhookConfiguration**: Admission webhook configuration

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
helm upgrade --install gatekeeper ./helm-charts/gatekeeper
```

**Note**: Helm automatically handles CRD installation before other resources.

## Usage Examples

### Deploy to Different Clusters

```bash
# Deploy to dev cluster
kubectl config use-context cadev
helm upgrade --install gatekeeper ./helm-charts/gatekeeper

# Deploy to prod cluster
kubectl config use-context caprod
helm upgrade --install gatekeeper ./helm-charts/gatekeeper
```

## Verification

```bash
# Check gatekeeper pods
kubectl get pods -n gatekeeper-system

# Check gatekeeper CRDs
kubectl get crds | grep gatekeeper

# List constraint templates
kubectl get constrainttemplates

# List mutations
kubectl get assign -A

# Check audit logs
kubectl logs -n gatekeeper-system -l control-plane=audit-controller
```

## Policy Management

### Adding New Policies

1. Create a new YAML file in `templates/` directory:
```yaml
# templates/my-policy.yaml
apiVersion: mutations.gatekeeper.sh/v1
kind: Assign
metadata:
  name: my-policy
spec:
  # ... policy specification
```

2. Deploy the policy:
```bash
helm upgrade --install gatekeeper ./helm-charts/gatekeeper
```

### Testing Policies

```bash
# Try creating a resource that violates a policy
kubectl apply -f test-resource.yaml

# Check audit results
kubectl get <constraint-kind> <constraint-name> -o yaml
```

## Architecture

### Components

1. **Gatekeeper Controller**:
   - Validates resources on admission
   - Enforces constraints in real-time
   - Runs as deployment with 3 replicas

2. **Gatekeeper Audit**:
   - Periodically audits existing resources
   - Reports violations for resources created before policy
   - Runs as deployment with 1 replica

3. **Validating Webhook**:
   - Intercepts API requests
   - Evaluates against defined constraints
   - Blocks non-compliant resources

### CRDs Included

- `ConstraintTemplate`: Defines policy logic
- `Assign`: Mutation to assign values
- `ModifySet`: Mutation to modify sets
- `AssignMetadata`: Mutation for metadata
- `Config`: Gatekeeper configuration

## Troubleshooting

### Webhook not working
Check webhook configuration:
```bash
kubectl get validatingwebhookconfigurations gatekeeper-validating-webhook-configuration -o yaml
```

### Pod admission errors
Check gatekeeper controller logs:
```bash
kubectl logs -n gatekeeper-system -l control-plane=controller-manager
```

### CRD issues
Verify CRDs are installed:
```bash
kubectl get crds | grep gatekeeper
```

### Bypass gatekeeper for debugging
Add label to namespace to exempt from policies:
```bash
kubectl label namespace <namespace> admission.gatekeeper.sh/ignore=true
```

## Upgrading

### From Previous Versions

This chart uses Gatekeeper 3.17.0. To upgrade:

```bash
# Backup existing constraints
kubectl get constraints -A -o yaml > constraints-backup.yaml

# Upgrade with Helm
helm upgrade gatekeeper ./helm-charts/gatekeeper

# Verify upgrade
kubectl get pods -n gatekeeper-system
```

## Uninstallation

```bash
# Uninstall the chart
helm uninstall gatekeeper

# Optional: Remove CRDs (WARNING: This deletes all policies)
kubectl delete crds -l gatekeeper.sh/system=yes
```

**Warning**: Uninstalling Gatekeeper removes all policy enforcement. This may allow non-compliant resources to be created.

## Behavior Preservation

This chart maintains **identical behavior** to the original `kubectl apply -f` workflow:
- All resources match original YAML files (version 3.17.0)
- No modifications to webhook configuration, RBAC, or controller settings
- CRD installation handled automatically by Helm
- Works across all cluster types (on-prem, AWS, Azure)

## GitOps Integration

Example ArgoCD Application:
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: gatekeeper
  namespace: argocd
spec:
  project: default
  source:
    repoURL: <your-repo-url>
    targetRevision: HEAD
    path: helm-charts/gatekeeper
  destination:
    server: https://kubernetes.default.svc
    namespace: gatekeeper-system
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
      - Replace=true  # Required for CRD updates
```

## Additional Resources

- Gatekeeper Documentation: https://open-policy-agent.github.io/gatekeeper/
- Version 3.17.0 Release Notes: https://github.com/open-policy-agent/gatekeeper/releases/tag/v3.17.0
- Policy Library: https://github.com/open-policy-agent/gatekeeper-library
