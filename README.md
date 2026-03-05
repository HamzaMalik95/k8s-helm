# YAML for various Medimpact Kubernetes resources:

## Documentation

Some diagrams as well as some how to stuff.

AAAA COMPLETE NUKE.txt shows how to completely reset/wipe/refresh a node (after removing from cluster of course)

## Examples

Just some example files

## Live

Real deployments using an layout (industry practice): shared Helm charts and per-environment values and cluster manifests.

- **`live/charts/`** — Shared Helm charts (single source of truth).
- **`live/environments/<env>/values/`** — Per-environment Helm value overrides.
- **`live/environments/<env>/cluster/`** — Raw Kubernetes YAML for that environment (namespaces, PVs, storage, etc.). Apply at the folder level, e.g. `kubectl apply -f live/environments/cadev/cluster/`.

See `live/README.md` and `live/environments/README.md` for the full structure.  
**How to deploy:** [live/DEPLOYMENT-GUIDE.md](live/DEPLOYMENT-GUIDE.md) (beginner-friendly).

## Old-archive

Older stuff for testing and deprecated setups
