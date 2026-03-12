# Roadmap:
Nginx repo: https://github.com/kubernetes/ingress-nginx

# Before upgrading k8s to 1.22
Due to a change in nginx ingress 1.3.1 leader election leases, first must upgrade from current 0.46.0 to 1.3.0. Nginx is version 1.19.10 and helm chart is 4.2.3. See https://github.com/kubernetes/ingress-nginx/releases/tag/controller-v1.3.1

helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm search repo ingress-nginx/ingress-nginx --versions
helm template ingress-nginx ingress-nginx/ingress-nginx --create-namespace --namespace=ingress-nginx --version "4.2.3" >> git/k8s/k8s-yamls/live/All-Clusters-BASE-REQUIRED/nginx-ingress-controller/new-ingress-heml.yaml
copy over relevant nginx config changes
add permissions to leader cm for ext
kubectl apply -f /mnt/d/git/k8s/k8s-yamls/live/All-Clusters-BASE-REQUIRED/nginx-ingress-controller/new --context calab
k delete cm -n ingress-nginx --context calab ingress-controller-leader-ext-nginx-ext ingress-controller-leader-nginx


Once on 1.3.0, then we can upgrade nginx ingress to 1.3.1, which is the highest version of nginx ingress that still supports k8s v1.21. Nginx version will be 1.19.10, and Helm chart will be 4.2.5

# After k8s upgrade to 1.22
k delete cm -n ingress-nginx --context cadev ingress-controller-leader ingress-controller-leader-ext
Upgrade nginx ingress to 1.4.0, which is the highest version that includes support for 1.22. Prometheus metric changes. https://github.com/kubernetes/ingress-nginx/pull/8728. Helm version 4.3.0.

# After k8s upgrade to 1.23
Upgrade nginx ingress to 1.6.4, which is the highest that supports 1.23. Skipping interim versions which have no important changes. Helm version 4.5.2

# After k8s upgrade to 1.24
Upgrade nginx to 1.8.4, which is the highest that supports 1.24. Skipping interim versions which have no important changes. Helm version 4.7.3.

# After k8s upgrade to 1.25
Upgrade to 1.9.6. Skipping interim versions which have no important changes. Helm version 4.9.1.

# After k8s upgrade to 1.26
Upgrade to 1.11.3. Helm version 4.11.3









# OLD NOTES
generated initially with
helm template ingress-nginx ingress-nginx/ingress-nginx --create-namespace --namespace=nginx-ingress --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-health-probe-request-path"=/healthz >> git/k8s/k8s-yamls/live/aks/ingress-heml.yaml


# this didnt work
helm template ingress-nginx ingress-nginx/ingress-nginx --create-namespace --namespace=nginx-ingress  --set controller.service.externalTrafficPolicy=Local --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-health-probe-request-path"=/healthz >> git/k8s/k8s-yamls/live/aks/ingress-helm2.yaml