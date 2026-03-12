# This provides the live k8s resource report under here

# Deployment steps:

Note each cluster has some unique configs for ingress and cluster role, so these are separated into folders based on the cluster name. The shared components that don't differentiate are at the root, but when applying these you MUST specify the namespace name, since this goes in the itsystems-lab/dev/prod namespace which is different again based on cluster.

1. First, deploy the clusterrole and ingress which is unique by cluster: `kubectl apply -f <cluster/folder name> --context <cluster name>`
2. Second, deploy the shared config, and must specify the namespace: `kubectl apply -f . -n <namespace name> --context <cluster name>`

# Example for the "calab" cluster:
```
mdeckert@vd1medsys0006:~/git/k8s/k8s-yamls/live/All-Clusters-BASE-REQUIRED/kube-reports$ kubectl apply -f calab/ --context calab
serviceaccount/kube-reports-serviceaccount unchanged
clusterrole.rbac.authorization.k8s.io/kube-reports-clusterrole unchanged
clusterrolebinding.rbac.authorization.k8s.io/kube-reports-clusterrole-binding unchanged
ingress.networking.k8s.io/kube-reports unchanged
mdeckert@vd1medsys0006:~/git/k8s/k8s-yamls/live/All-Clusters-BASE-REQUIRED/kube-reports$ kubectl apply -f . -n itsystems-lab --context calab
deployment.apps/kube-reports configured
networkpolicy.networking.k8s.io/nginx-ingress.kube-reports.8080 unchanged
service/kube-reports unchanged
mdeckert@vd1medsys0006:~/git/k8s/k8s-yamls/live/All-Clusters-BASE-REQUIRED/kube-reports$
```