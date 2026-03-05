sudo DOCKER_BUILDKIT=1 docker build --build-arg="OPENCVE_VERSION=1.4.1" --build-arg="OPENCVE_REPOSITORY=https://github.com/opencve/opencve.git" -t docker-local.artifactory.medimpact.com/com.medimpact/itsec/opencve:1.4.1 .


kubectl apply -f /mnt/d/git/k8s/k8s-yamls/live/lab/opencve/base-setup -n itsec-dev
kubectl apply -f /mnt/d/git/k8s/k8s-yamls/live/lab/opencve/jobs/1-job-upgradedb.yaml -n itsec-dev
kubectl apply -f /mnt/d/git/k8s/k8s-yamls/live/lab/opencve/jobs/2-job-importdata.yaml -n itsec-dev
kubectl logs jobname -n itsec-dev -f
kubectl apply -f /mnt/d/git/k8s/k8s-yamls/live/lab/opencve -n itsec-dev

kubectl exec -it -n itsec-dev podname -- bash
opencve create-user admin mdeckert@medimpact.com -- admin