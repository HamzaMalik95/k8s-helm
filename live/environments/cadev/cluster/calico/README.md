# Relatively current manifests are in github like this
https://raw.githubusercontent.com/projectcalico/calico/v3.25.2/manifests/calico-typha.yaml

# Old ones are still in github like this:
https://projectcalico.docs.tigera.io/archive/v3.24/manifests/calico-typha.yaml

# Check k8s support matrix like this:
https://docs.tigera.io/calico/3.25/getting-started/kubernetes/requirements

# Copy images to aritfactory like this
skopeo copy docker://docker.io/calico/cni:v3.26.4 docker://docker-local.artifactory.medimpact.com/docker.io/calico/cni:v3.26.4
skopeo copy docker://docker.io/calico/node:v3.26.4 docker://docker-local.artifactory.medimpact.com/docker.io/calico/node:v3.26.4
skopeo copy docker://docker.io/calico/kube-controllers:v3.26.4 docker://docker-local.artifactory.medimpact.com/docker.io/calico/kube-controllers:v3.26.4
skopeo copy docker://docker.io/calico/typha:v3.26.4 docker://docker-local.artifactory.medimpact.com/docker.io/calico/typha:v3.26.4


# IMPORTANT: must change the CALICO_IPV4POOL_CIDR in the config to the correct internal pod subnet for the cluster