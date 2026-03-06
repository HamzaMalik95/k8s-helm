# Testing This Repo (Helm + kubectl)

This guide shows how to test the Helm charts and cluster YAML **without applying anything** and **without needing a cluster or login**. Use it to verify syntax and that values merge correctly.

**Run all commands from the repository root** (the folder that contains `live/`).

---

## Prerequisites

- **Helm 3** — `helm version`
- **kubectl** — `kubectl version --client`

No cluster or kubeconfig required for the checks below (we use client-only dry-runs and, for kubectl, an empty kubeconfig so no login is triggered).

---

## 1. Test Helm charts (no cluster)

Helm **template** renders charts with base + environment values. It does not contact any cluster.

### One chart, one environment

```bash
# Example: nginx-ingress for cadev
helm template nginx-ingress live/charts/nginx-ingress \
  -f live/charts/nginx-ingress/values.yaml \
  -f live/environments/cadev/values/nginx-ingress.yaml \
  -n ingress-nginx
```

If you see valid YAML and no errors, the chart and values are valid. Repeat for other charts and envs by changing chart name, paths, and `-n` (namespace) as in [DEPLOYMENT-GUIDE.md](DEPLOYMENT-GUIDE.md).

### Fluentd (requires clusterName in env values)

```bash
helm template fluentd live/charts/fluentd \
  -f live/charts/fluentd/values.yaml \
  -f live/environments/cadev/values/fluentd.yaml \
  -n fluentd
```

### Test all charts for one environment (cadev)

```bash
env=cadev
for chart in nginx-ingress metrics-server coredns fluentd eventrouter gatekeeper kube-reports rbac; do
  echo "=== $env / $chart ==="
  helm template $chart live/charts/$chart \
    -f live/charts/$chart/values.yaml \
    -f live/environments/$env/values/$chart.yaml \
    -n default
done
```

Any failure will print an error; success prints a stream of YAML.

### Test one chart across all environments

```bash
chart=nginx-ingress
for env in cadev caprod lab; do
  echo "=== $env / $chart ==="
  helm template $chart live/charts/$chart \
    -f live/charts/$chart/values.yaml \
    -f live/environments/$env/values/$chart.yaml \
    -n default
done
```

---

## 2. Test cluster YAML with kubectl (syntax only, no login)

These commands validate that the YAML in `live/environments/<env>/cluster/` is valid. They **do not** connect to any cluster or use your kubeconfig (no `tsh login` or similar).

### One environment (e.g. cadev)

```bash
find live/environments/cadev/cluster -type f \( -name '*.yaml' -o -name '*.yml' \) -exec sh -c 'KUBECONFIG=/dev/null kubectl apply -f "$1" --dry-run=client --validate=false -o yaml > /dev/null' _ {} \;
echo "Cluster YAML syntax check done for cadev"
```

- **`KUBECONFIG=/dev/null`** — kubectl does not load your config, so no login/Teleport.
- **`--dry-run=client`** — local only, no API calls.
- **`--validate=false`** — no OpenAPI fetch; syntax/structure only.

### See which file failed (if any)

```bash
find live/environments/cadev/cluster -type f \( -name '*.yaml' -o -name '*.yml' \) -exec sh -c 'KUBECONFIG=/dev/null kubectl apply -f "$1" --dry-run=client --validate=false -o yaml > /dev/null || echo "FAILED: $1"' _ {} \;
```

### All environments (cadev, caprod, lab)

```bash
for env in cadev caprod lab; do
  echo "=== Checking $env cluster YAML ==="
  find live/environments/$env/cluster -type f \( -name '*.yaml' -o -name '*.yml' \) -exec sh -c 'KUBECONFIG=/dev/null kubectl apply -f "$1" --dry-run=client --validate=false -o yaml > /dev/null || echo "FAILED: $1"' _ {} \;
done
echo "Done"
```

---

## 3. Optional: test with a real cluster

If you have a cluster and want to confirm resources would be accepted by the API (still no create/update):

- **Helm:** use the same `helm template` as above, then pipe to kubectl:
  ```bash
  helm template nginx-ingress live/charts/nginx-ingress \
    -f live/charts/nginx-ingress/values.yaml \
    -f live/environments/cadev/values/nginx-ingress.yaml \
    -n ingress-nginx | kubectl apply -f - --dry-run=server
  ```
- **Cluster YAML:** point kubectl at your cluster and run:
  ```bash
  find live/environments/cadev/cluster -type f \( -name '*.yaml' -o -name '*.yml' \) -exec kubectl apply -f {} --dry-run=server \;
  ```

---

## Quick reference

| What you want to test | Command |
|------------------------|--------|
| One Helm chart + env   | `helm template <release> live/charts/<chart> -f live/charts/<chart>/values.yaml -f live/environments/<env>/values/<chart>.yaml -n <namespace>` |
| All Helm charts for one env | Use the `for chart in ...` loop in section 1. |
| Cluster YAML syntax (no login) | `find live/environments/<env>/cluster -type f \( -name '*.yaml' -o -name '*.yml' \) -exec sh -c 'KUBECONFIG=/dev/null kubectl apply -f "$1" --dry-run=client --validate=false -o yaml > /dev/null' _ {} \;` |

All of the above are **dry-run / syntax checks** only; nothing is applied to a cluster unless you run `kubectl apply` or `helm upgrade --install` without `--dry-run`.
