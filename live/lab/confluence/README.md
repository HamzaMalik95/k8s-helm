# Helm install procedures

```
helm repo add atlassian-data-center \
 https://atlassian.github.io/data-center-helm-charts
```

```
helm repo update
```

```
helm show values atlassian-data-center/confluence > git/k8s/k8s-yamls/live/lab/confluence/values.yaml
```

Make mods to values.yaml first

```
helm template confluence \
             atlassian-data-center/confluence \
             --namespace itapps-dev \
             --version 1 \
             --values git/k8s/k8s-yamls/live/lab/confluence/values.yaml \
             > git/k8s/k8s-yamls/live/lab/confluence/confluence-helm.yaml
```