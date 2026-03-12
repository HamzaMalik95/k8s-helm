## CPI folder:
This is the VSphere Cloud Provider Interface. It communicates between vcenter and k8s to update annotations and node topology based on vsphere topology. This is required for the CSI to work correctly.

The version of CPI should match the version of k8s. Vmware/Kubernetes publishes the manifests by version here https://github.com/kubernetes/cloud-provider-vsphere/tree/master/releases

## CSI folder:
This is the Vsphere Container Storage Interface. This creates deletes mounts and syncs vmdks and persistent volumes.

The manifests can be found here (the link is for 2.4. Adjust the release branch as necessary)
https://github.com/kubernetes-sigs/vsphere-csi-driver/tree/release-2.4/manifests/vanilla

Carefully read upgrade instructions as there may be specific actions depending on current version and upgraded version: https://docs.vmware.com/en/VMware-vSphere-Container-Storage-Plug-in/2.0/vmware-vsphere-csp-getting-started/GUID-3F277B52-68CC-4125-AD0F-E7293940B4B4.html

## Copy images to artifactory like this, and update all lines defining "image: "
skopeo copy docker://registry.k8s.io/sig-storage/csi-attacher:v4.3.0 docker://docker-local.artifactory.medimpact.com/registry.k8s.io/sig-storage/csi-attacher:v4.3.0
skopeo copy docker://registry.k8s.io/sig-storage/csi-resizer:v1.8.0 docker://docker-local.artifactory.medimpact.com/registry.k8s.io/sig-storage/csi-resizer:v1.8.0
skopeo copy docker://registry.k8s.io/sig-storage/livenessprobe:v2.10.0 docker://docker-local.artifactory.medimpact.com/registry.k8s.io/sig-storage/livenessprobe:v2.10.0
skopeo copy docker://registry.k8s.io/sig-storage/csi-provisioner:v3.5.0 docker://docker-local.artifactory.medimpact.com/registry.k8s.io/sig-storage/csi-provisioner:v3.5.0
skopeo copy docker://registry.k8s.io/sig-storage/csi-snapshotter:v6.2.2 docker://docker-local.artifactory.medimpact.com/registry.k8s.io/sig-storage/csi-snapshotter:v6.2.2
skopeo copy docker://registry.k8s.io/sig-storage/csi-node-driver-registrar:v2.8.0 docker://docker-local.artifactory.medimpact.com/registry.k8s.io/sig-storage/csi-node-driver-registrar:v2.8.0

## Taint new nodes for CSI to find them. Example:
kubectl taint node dv1medk8no01 node.cloudprovider.kubernetes.io/uninitialized=true:NoSchedule --context cadev

# If syncer/driver need to be built (Hopefully never again)
git clone https://github.com/kubernetes-sigs/vsphere-csi-driver.git && \
git checkout tags/v3.3.1 && \
sudo docker build -f images/driver-base/Dockerfile -t gcr.io/cloud-provider-vsphere/extra/csi-driver-base:latest . && \
sudo docker build -f images/syncer/Dockerfile -t docker-local.artifactory.medimpact.com/gcr.io/cloud-provider-vsphere/csi/release/syncer:v3.3.1 . && \
sudo docker push docker-local.artifactory.medimpact.com/gcr.io/cloud-provider-vsphere/csi/release/syncer:v3.3.1 && \
sudo docker rmi docker-local.artifactory.medimpact.com/gcr.io/cloud-provider-vsphere/csi/release/syncer:v3.3.1 && \
sudo docker build -f images/driver/Dockerfile -t docker-local.artifactory.medimpact.com/gcr.io/cloud-provider-vsphere/csi/release/driver:v3.3.1 . && \
sudo docker push docker-local.artifactory.medimpact.com/gcr.io/cloud-provider-vsphere/csi/release/driver:v3.3.1 && \
sudo docker rmi docker-local.artifactory.medimpact.com/gcr.io/cloud-provider-vsphere/csi/release/driver:v3.3.1 && \
sudo docker rmi gcr.io/cloud-provider-vsphere/extra/csi-driver-base:latest


CSI version Compatibility Matrix as of 1/20/2025
vSphere Container Storage Plug-in	Minimum Kubernetes Release	Maximum Kubernetes Release	EOL Date
3.3.1	1.27	1.30	September 2026
3.3.0	1.28	1.30	September 2026
3.2.0	1.27	1.29	March 2026
3.1.2	1.26	1.28	September 2025
3.1.1	1.26	1.28	September 2025
3.1.0	1.26	1.28	September 2025
3.0.3	1.24	1.27	March 2025
3.0.2	1.24	1.27	March 2025
3.0.1	1.24	1.27	March 2025
3.0.0	1.24	1.27	March 2025