# Live deployments (Option C layout)

Industry-standard layout: one shared chart set, per-environment values and cluster manifests.

## Structure

```
live/
├── charts/                    # Shared Helm charts (single source of truth)
│   ├── nginx-ingress/
│   │   ├── Chart.yaml
│   │   ├── values.yaml        # Base defaults
│   │   └── templates/
│   ├── metrics-server/
│   ├── coredns/
│   ├── fluentd/
│   ├── eventrouter/
│   ├── gatekeeper/
│   ├── kube-reports/
│   └── rbac/
└── environments/              # Per-environment config and manifests
    ├── cadev/
    │   ├── values/            # Helm value overrides per chart
    │   │   ├── nginx-ingress.yaml
    │   │   ├── metrics-server.yaml
    │   │   ├── fluentd.yaml    # e.g. clusterName: "cadev"
    │   │   └── ...
    │   └── cluster/           # Cluster-specific raw YAML (namespaces, PVs, storage, etc.)
    ├── caprod/
    │   ├── values/
    │   └── cluster/
    └── lab/
        ├── values/
        └── cluster/
```

## Conventions

- **charts/** — Reusable Helm charts; no duplication per environment.
- **environments/<env>/values/** — Per-environment overrides only (one file per chart, e.g. `nginx-ingress.yaml`).
- **environments/<env>/cluster/** — Raw Kubernetes YAML for that environment (namespaces, PVs/PVCs, storage classes, CNI, injectors, etc.).
- New environment = new folder under `environments/` with `values/` and `cluster/` subfolders.

See `environments/README.md` for details on the values layout and chart list.

**→ Step-by-step deployment:** [DEPLOYMENT-GUIDE.md](DEPLOYMENT-GUIDE.md) — how the environment structure works and how to deploy (beginner-friendly).
