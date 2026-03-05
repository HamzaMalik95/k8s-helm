Retrieved manifest from:
https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

Moved redis image to artifactory
docker-local.artifactory.medimpact.com/dockerhub/redis:7.0.7-alpine

Modified imagePullPolicy to IfNotPresent

# Add runAsUser to argocd-applicationset-controller deployment
# 
#       securityContext:
#         runAsUser: 1000

Must apply with namespace as an arg.  Example:

k apply -f git/k8s/k8s-yamls/live/lab/argocd/1-deploy-argocd.yaml -n argocd --context calab