# Environments (Option C)

Per-environment configuration: Helm value overrides and cluster-specific manifests.

## Layout

```
environments/
├── cadev/
│   ├── values/              # Helm overrides (base chart + this file per chart)
│   │   ├── nginx-ingress.yaml
│   │   ├── metrics-server.yaml
│   │   ├── coredns.yaml
│   │   ├── fluentd.yaml      # set clusterName: "cadev"
│   │   ├── eventrouter.yaml
│   │   ├── gatekeeper.yaml
│   │   ├── kube-reports.yaml
│   │   └── rbac.yaml
│   └── cluster/             # Raw YAML for this env (namespaces, PVs, storage, etc.)
├── caprod/
│   ├── values/
│   └── cluster/
└── lab/
    ├── values/
    └── cluster/
```

## Charts and override files

| Chart          | Chart path (under `../charts/`) | Values override (under `values/`) |
|----------------|---------------------------------|-----------------------------------|
| nginx-ingress  | `nginx-ingress`                 | `nginx-ingress.yaml`              |
| metrics-server | `metrics-server`               | `metrics-server.yaml`             |
| coredns        | `coredns`                      | `coredns.yaml`                    |
| fluentd        | `fluentd`                      | `fluentd.yaml` (set `clusterName`) |
| eventrouter    | `eventrouter`                  | `eventrouter.yaml`                |
| gatekeeper     | `gatekeeper`                   | `gatekeeper.yaml`                 |
| kube-reports   | `kube-reports`                 | `kube-reports.yaml`               |
| rbac           | `rbac`                         | `rbac.yaml`                       |

## Rules

- **Charts** live only under `../charts/`; do not copy charts per environment.
- **values/** files contain only overrides (replicas, resources, `clusterName`, etc.).
- **cluster/** holds everything that is applied as raw YAML for that environment (e.g. `kubectl apply -f cluster/`).
- To add a new environment: create `environments/<new-env>/values/` and `environments/<new-env>/cluster/`, and add the same set of values files with env-specific content.
