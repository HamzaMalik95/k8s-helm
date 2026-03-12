generated initially with
helm template ingress-nginx ingress-nginx/ingress-nginx --create-namespace --namespace=nginx-ingress --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-health-probe-request-path"=/healthz >> git/k8s/k8s-yamls/live/aks/ingress-heml.yaml


# this didnt work
helm template ingress-nginx ingress-nginx/ingress-nginx --create-namespace --namespace=nginx-ingress  --set controller.service.externalTrafficPolicy=Local --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-health-probe-request-path"=/healthz >> git/k8s/k8s-yamls/live/aks/ingress-helm2.yaml