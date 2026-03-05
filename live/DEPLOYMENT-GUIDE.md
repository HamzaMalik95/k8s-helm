# How This Repo Works & How to Deploy (Beginner-Friendly)

This guide explains the **environment-based structure** and how to deploy to each environment. No prior Helm experience required.

---

## 1. The Big Idea

- **One set of Helm charts** lives in `charts/`. Same charts for every environment.
- **Each environment** (e.g. dev, prod, lab) has its own folder under `environments/<env>/` with:
  - **values/** — small YAML files that only override what’s different for that env (replicas, cluster name, etc.).
  - **cluster/** — plain Kubernetes YAML (namespaces, storage, etc.) applied with `kubectl apply -f ...`.

You **don’t copy charts** per environment. You only add **values files** and **cluster YAML** per environment.

---

## 2. Folder Structure (What Lives Where)

```
live/
├── charts/                          ← All Helm charts (shared)
│   ├── nginx-ingress/
│   │   ├── Chart.yaml
│   │   ├── values.yaml              ← Base defaults
│   │   └── templates/
│   ├── metrics-server/
│   ├── fluentd/
│   └── ...                          (one folder per chart)
│
└── environments/                    ← One folder per environment
    ├── cadev/                       ← e.g. "CA Dev"
    │   ├── values/                  ← Helm overrides for this env
    │   │   ├── nginx-ingress.yaml
    │   │   ├── metrics-server.yaml
    │   │   ├── fluentd.yaml         ← e.g. clusterName: "cadev"
    │   │   └── ...
    │   └── cluster/                 ← Raw K8s YAML for this env
    │       ├── namespaces/
    │       ├── persistentvolumes/
    │       └── ...
    ├── caprod/                      ← e.g. "CA Prod"
    │   ├── values/
    │   └── cluster/
    └── lab/
        ├── values/
        └── cluster/
```

- **charts/** = reusable Helm charts (single source of truth).
- **environments/<env>/values/** = “only what’s different for this env” (one file per chart).
- **environments/<env>/cluster/** = everything you apply with `kubectl apply -f ...` for that env.

---

## 3. What You Need Before Deploying

- **kubectl** installed and configured.
- **Helm 3** installed (`helm version`).
- **kubeconfig** pointing at the right cluster (e.g. dev, prod, or lab).

Switch cluster (example):

```bash
kubectl config use-context <your-dev-context>
# or
kubectl config use-context <your-prod-context>
```

---

## 4. How to Deploy (Step by Step)

### Step 1: Choose your environment

Pick one: `cadev`, `caprod`, or `lab`. All commands below use **cadev** as an example; replace with your env.

### Step 2: Apply cluster YAML (namespaces, storage, etc.)

From the **repo root** (the folder that contains `live/`):

```bash
kubectl apply -f live/environments/cadev/cluster/
```

This applies everything in `environments/cadev/cluster/` (namespaces, PVs, configs, etc.). Run it once per environment when you onboard or update that env.

### Step 3: Install or upgrade Helm charts (base + env values)

For each chart you want in that environment, use **two** values files:

1. The chart’s **base** `values.yaml` (in `charts/<chart>/values.yaml`).
2. The **environment override** (in `environments/<env>/values/<chart>.yaml`).

General form (run from **repo root**):

```bash
helm upgrade --install <release-name> live/charts/<chart-name> \
  -f live/charts/<chart-name>/values.yaml \
  -f live/environments/<env>/values/<chart-name>.yaml \
  -n <namespace>
```

**Examples for environment `cadev`:**

```bash
# Nginx Ingress
helm upgrade --install nginx-ingress live/charts/nginx-ingress \
  -f live/charts/nginx-ingress/values.yaml \
  -f live/environments/cadev/values/nginx-ingress.yaml \
  -n ingress-nginx

# Metrics Server
helm upgrade --install metrics-server live/charts/metrics-server \
  -f live/charts/metrics-server/values.yaml \
  -f live/environments/cadev/values/metrics-server.yaml \
  -n kube-system

# Fluentd (needs clusterName in env values, e.g. "cadev")
helm upgrade --install fluentd live/charts/fluentd \
  -f live/charts/fluentd/values.yaml \
  -f live/environments/cadev/values/fluentd.yaml \
  -n fluentd
```

For **caprod** or **lab**, only change the env name:

```bash
# Same chart, different env
helm upgrade --install nginx-ingress live/charts/nginx-ingress \
  -f live/charts/nginx-ingress/values.yaml \
  -f live/environments/caprod/values/nginx-ingress.yaml \
  -n ingress-nginx
```

So: **same chart**, **same base values**, **different env values file** = different environment.

---

## 5. Quick Reference: Charts and Namespaces

| Chart           | Typical namespace   | Env values file              |
|-----------------|---------------------|------------------------------|
| nginx-ingress   | `ingress-nginx`     | `nginx-ingress.yaml`         |
| metrics-server  | `kube-system`       | `metrics-server.yaml`        |
| coredns         | `kube-system`       | `coredns.yaml`               |
| fluentd         | `fluentd`           | `fluentd.yaml` (set `clusterName`) |
| eventrouter     | `kube-system`       | `eventrouter.yaml`           |
| gatekeeper      | `gatekeeper-system` | `gatekeeper.yaml`            |
| kube-reports    | (your choice)       | `kube-reports.yaml`          |
| rbac            | `kube-system`       | `rbac.yaml`                  |

Create the namespace first if it doesn’t exist (often done by something in `cluster/` or manually):

```bash
kubectl create namespace ingress-nginx
# then run the helm command
```

---

## 6. Adding a New Environment

1. Create the folder structure:

   ```bash
   mkdir -p live/environments/staging/values
   mkdir -p live/environments/staging/cluster
   ```

2. Copy one env’s **values** files as a template (e.g. from `cadev`):

   ```bash
   cp live/environments/cadev/values/*.yaml live/environments/staging/values/
   ```

3. Edit each file under `staging/values/` and set what’s different for staging (e.g. `clusterName: "staging"` in `fluentd.yaml`, smaller replicas, etc.).

4. Put any env-specific raw YAML (namespaces, PVs, etc.) in `staging/cluster/`.

5. Deploy:

   ```bash
   kubectl apply -f live/environments/staging/cluster/
   helm upgrade --install nginx-ingress live/charts/nginx-ingress \
     -f live/charts/nginx-ingress/values.yaml \
     -f live/environments/staging/values/nginx-ingress.yaml \
     -n ingress-nginx
   # ... repeat for other charts
   ```

---

## 7. Summary

| Goal                         | What to do |
|-----------------------------|------------|
| Deploy cluster YAML for env | `kubectl apply -f live/environments/<env>/cluster/` |
| Deploy a Helm chart for env | `helm upgrade --install ... -f live/charts/<chart>/values.yaml -f live/environments/<env>/values/<chart>.yaml -n <ns>` |
| Change something per env    | Edit only `live/environments/<env>/values/<chart>.yaml` (or files in `cluster/`). |
| Add a new environment       | Add `environments/<new-env>/values/` and `cluster/`, then use the same helm pattern with the new env name. |

The Helm chart stays in **one place** (`charts/`). The **environment** is chosen by which **values file** and **cluster/** folder you use.
