#!/bin/bash

set -e

KUBERNETES_VERSION=1.28.15  #Next version 1.27.16 #prev version 1.26.15 #really future: 1.28.15
CNI_PLUGINS_VERSION=v1.6.0
CONTAINERD_VERSION=1.7.23
CRICTL_VERSION=v1.29.0
KREL_VERSION=v0.17.10
RUNC_VERSION=v1.1.15
ARCH=amd64

MAX_JOBS=7       # Maximum concurrent patch jobs. Recommend 20% or less of number of nodes in cluster
MINIMUM_DELAY_BETWEEN_STARTS=90      # Minimum gap in seconds between starting additional jobs. Recommended 90.
MAX_NOTREADY_PODS=40 # Maximum number of pods that can be NOT in Ready status. Recommended 25 in azprod. 40 in caprod/cadev. 10 in lab.

stop_flag=false
# On Ctrl-C, set a flag telling the script to stop launching new jobs.
trap "echo '[INFO] Caught Ctrl-C. No new jobs will be started...'; stop_flag=true" SIGINT

# Check if --context parameter is provided
if [ -z "$1" ]; then
  echo "Error: --context must be set."
  echo "Usage: $0 --context <context_name>"
  exit 1
fi

# Extract the context from the first parameter
if [[ "$1" == "--context" && -n "$2" ]]; then
  CONTEXT=$2
else
  echo "Error: Invalid parameters."
  echo "Usage: $0 --context <context_name>"
  exit 1
fi

printf "Enter the username: "
read username
printf "Enter the password: "
read -s password

K8S_BIN_DIR=/opt/app/kubernetes/bin
DEST=/opt/cni/bin

NODE_LIST=$(kubectl get nodes --context "$CONTEXT" --selector='!node-role.kubernetes.io/control-plane' --no-headers | grep -v "$KUBERNETES_VERSION" | awk '{print $1}')
# NODE_LIST=$(kubectl get nodes --context "$CONTEXT" --selector='!node-role.kubernetes.io/control-plane' --no-headers | awk '{print $1}')

# Create a local temp dir
PACKAGES_DIR=$(mktemp -d)
echo Downloading packages to $PACKAGES_DIR

# Download the packages to the temp dir
(cd "${PACKAGES_DIR}" && \
    curl -L --remote-name-all "https://github.com/containernetworking/plugins/releases/download/${CNI_PLUGINS_VERSION}/cni-plugins-linux-${ARCH}-${CNI_PLUGINS_VERSION}.tgz" && \
    curl -L --remote-name-all "https://github.com/kubernetes-sigs/cri-tools/releases/download/${CRICTL_VERSION}/crictl-${CRICTL_VERSION}-linux-${ARCH}.tar.gz" && \
    curl -L --remote-name-all "https://dl.k8s.io/release/v${KUBERNETES_VERSION}/bin/linux/${ARCH}/kubeadm" && \
    curl -L --remote-name-all "https://raw.githubusercontent.com/kubernetes/release/${KREL_VERSION}/cmd/krel/templates/latest/kubelet/kubelet.service" && \
    curl -L --remote-name-all "https://raw.githubusercontent.com/kubernetes/release/${KREL_VERSION}/cmd/krel/templates/latest/kubeadm/10-kubeadm.conf" && \
    curl -L --remote-name-all "https://dl.k8s.io/release/v${KUBERNETES_VERSION}/bin/linux/${ARCH}/kubelet" && \
    curl -L --remote-name-all "https://github.com/containerd/containerd/releases/download/v${CONTAINERD_VERSION}/containerd-${CONTAINERD_VERSION}-linux-${ARCH}.tar.gz" && \
    curl -L --remote-name-all "https://raw.githubusercontent.com/containerd/containerd/main/containerd.service" && \
    curl -L "https://github.com/opencontainers/runc/releases/download/${RUNC_VERSION}/runc.${ARCH}" -o runc)

# Create the creds source file and passphrase
PASSPHRASE=$(openssl rand -base64 24 | tr -dc 'a-zA-Z0-9' | head -c32)
echo Generated unique passphrase: $PASSPHRASE
CRED_FILE="${PACKAGES_DIR}/cred"
echo "export REMOTE_PASSWORD=\"${password}\"" | openssl enc -pbkdf2 -base64 -pass pass:$PASSPHRASE > $CRED_FILE
chmod 400 $CRED_FILE

# Create the patch script
PATCH_SCRIPT="${PACKAGES_DIR}/patch.sh"

cat <<EOF > "$PATCH_SCRIPT"
#!/bin/bash

set -e

yum upgrade -y

# 1. Install the CNI plugins
tar -C "${DEST}" -xzf ${PACKAGES_DIR}/cni-plugins-linux-${ARCH}-${CNI_PLUGINS_VERSION}.tgz

# 2. Install crictl
tar -C "${K8S_BIN_DIR}" -xzf ${PACKAGES_DIR}/crictl-${CRICTL_VERSION}-linux-${ARCH}.tar.gz

# 3. Install kubeadm
yes | cp ${PACKAGES_DIR}/kubeadm ${K8S_BIN_DIR} && chmod +x ${K8S_BIN_DIR}/kubeadm

# 4. Install the Kubernetes RELease tooling and infrastructure (systemd files)
sed "s:/usr/bin:${K8S_BIN_DIR}:g" ${PACKAGES_DIR}/kubelet.service > /etc/systemd/system/kubelet.service
sed "s:/usr/bin:${K8S_BIN_DIR}:g" ${PACKAGES_DIR}/10-kubeadm.conf > /etc/systemd/system/kubelet.service.d/10-kubeadm.conf

systemctl daemon-reload

# 5. Upgrade k8s
${K8S_BIN_DIR}/kubeadm upgrade node

# 6. Upgrade kubelet
systemctl stop kubelet
yes | cp ${PACKAGES_DIR}/kubelet ${K8S_BIN_DIR}/kubelet && chmod +x ${K8S_BIN_DIR}/kubelet

# 7. Upgrade containerd
systemctl stop containerd
# mkdir -p /opt/app/containerd/bin ###### ONE TIME ONLY
tar -C /opt/app/containerd -xzf ${PACKAGES_DIR}/containerd-${CONTAINERD_VERSION}-linux-${ARCH}.tar.gz
systemctl daemon-reload
systemctl start containerd # Validate that it actually starts

# 8. Cleanup and restart
echo Cleaning up old container images
${K8S_BIN_DIR}/crictl rmi --prune > /dev/null 2>&1
systemctl stop containerd
sleep 2
bash -c "rm -rf /opt/app/containerd/var/* || true" > /dev/null 2>&1
shutdown -r +1
# nohup bash -c "sleep 5; shutdown -r now" >/dev/null 2>&1 &
EOF

chmod +x "$PATCH_SCRIPT"

patch_node() {
    local server="$1"
    
    echo "patching $server"
    
    kubectl label node $server --context "$CONTEXT" node-role.kubernetes.io/upgrade-in-progress=

    kubectl drain "$server" --ignore-daemonsets --delete-emptydir-data --force --grace-period=120 --context "$CONTEXT"

    echo "Copying packages in ${PACKAGES_DIR} to $server"
    
    # Copy the packages to the remote server
    sshpass -p "$password" scp -r -q -o StrictHostKeyChecking=no "${PACKAGES_DIR}" "$username@$server:${PACKAGES_DIR}"
    
    # Decrypt the creds
    DECRED_FILE="${PACKAGES_DIR}/cred.de"
    sshpass -p "$password" ssh -t -t -q -o StrictHostKeyChecking=no "$username@$server" "cat $CRED_FILE | openssl enc -pbkdf2 -base64 -d -pass pass:$PASSPHRASE > ${DECRED_FILE} && chmod 400 ${DECRED_FILE}"
    
    # Execute the script
    sshpass -p "$password" ssh -t -t -q -o StrictHostKeyChecking=no "$username@$server" "source $DECRED_FILE && printf '%s\n' \"\$REMOTE_PASSWORD\" | sudo -p \"\" -S bash ${PATCH_SCRIPT}"

    until sshpass -p "$password" ssh -t -t -q -o StrictHostKeyChecking=no "$username@$server" "source $DECRED_FILE && printf '%s\n' \"\$REMOTE_PASSWORD\" | sudo -p \"\"  -S systemctl is-active --quiet kubelet"; do
        echo "Waiting for $server and its kubelet to restart..."
        sleep 5
    done

    echo "Kubelet is active on $server. Waiting for critical control plane components to be ready."
    
    kubectl -n kube-system wait --for=condition=Ready pods -l k8s-app=kube-proxy --timeout=999999s --field-selector spec.nodeName=$server --context "$CONTEXT"
    kubectl -n kube-system wait --for=condition=Ready pods -l k8s-app=calico-node --timeout=999999s --field-selector spec.nodeName=$server --context "$CONTEXT"
    kubectl -n vmware-system-csi wait --for=condition=Ready pods -l app=vsphere-csi-node --timeout=999999s --field-selector spec.nodeName=$server --context "$CONTEXT"
    kubectl label node $server --context "$CONTEXT" node-role.kubernetes.io/upgrade-in-progress-
    kubectl uncordon "$server" --context "$CONTEXT"
      
    # Delete the packages on the server
    sshpass -p "$password" ssh -t -t -q -o StrictHostKeyChecking=no "$username@$server" "rm -rf ${PACKAGES_DIR} || true"

    secs=$((1 * 10))
    while [ $secs -gt 0 ]; do
        # echo -ne "$server complete. Patching next node in $secs seconds\033[0K\r"
        echo "$server complete. Patching next node in $secs seconds"
        sleep 1
        : $((secs--))
    done
    printf "\n"
}


last_job_start=0 # Tracks the last time (epoch seconds) we started a job

while read server <&3; do
    if $stop_flag; then
        echo "[INFO] stop_flag is set. Exiting loop now."
        break
    fi
    
    # Control the maximum number of nodes that can be in an upgrade at once
    while [[ $(jobs -r -p | wc -l) -ge "$MAX_JOBS" ]]; do
        sleep 2
    done
    
    # Check ready pod count and hold for now if there are too many unready pods
    while true; do
        # Give a moment between the last node drain otherwise pods may not quite be marked unready yet
        sleep 2
        
        NOTREADY_POD_COUNT=$(kubectl get pods -A -o custom-columns=STATUS:.status.phase,READY:.status.containerStatuses[*].ready --no-headers --context "$CONTEXT" | awk '/false/ || !/Running/'|wc -l)
        
        # Make sure NOTREADY_POD_COUNT is a number and the query didn't just fail or something
        if ! echo "$NOTREADY_POD_COUNT" | grep -qE '^[0-9]+$'; then
            echo "Failed to get a valid pod count. Waiting another 10 seconds..."
            sleep 10
            continue
        fi
        
        if [ $NOTREADY_POD_COUNT -gt $MAX_NOTREADY_PODS ]; then
            echo "Not ready pod count: $NOTREADY_POD_COUNT is greater than maximum allowed: $MAX_NOTREADY_PODS. Waiting..."
            sleep 10
        else
            break
            echo "Not ready pod count $NOTREADY_POD_COUNT is less than maximum allowed: $MAX_NOTREADY_PODS. Continuing..."
        fi
    done
    
    # Don't do anything yet until typha is fully up since that can hold calico which can hold pods
    kubectl rollout status -n kube-system deploy/calico-typha --context $CONTEXT
    
    # Allow at least a configurable period of time between the start of new node upgrades
    now=$(date +%s)
    time_since_last_start=$(( now - last_job_start ))
    
    if [[ $time_since_last_start -lt $MINIMUM_DELAY_BETWEEN_STARTS ]]; then
        to_sleep=$(( MINIMUM_DELAY_BETWEEN_STARTS - time_since_last_start ))
        echo "[INFO] Sleeping $to_sleep seconds to maintain $MINIMUM_DELAY_BETWEEN_STARTS-second gap"
        sleep "$to_sleep"
    fi
    
    patch_node "$server" &
    
    last_job_start=$(date +%s)
done 3<<<"$NODE_LIST"

# Wait for all background jobs to finish
wait
echo "[INFO] All patches complete."

# Clean up the temporary script
rm -rf "${PACKAGES_DIR}"

echo "[INFO] The following pods are not in Ready or Running status (If any)"
kubectl get pods -A -o custom-columns=NAMESPACE:.metadata.namespace,POD:.metadata.name,STATUS:.status.phase,READY:.status.containerStatuses[*].ready --no-headers --context "$CONTEXT" | awk '/false/ || !/Running/'

echo "[INFO] The following replicasets have pods that are not completely rolled out (If any)"
kubectl get rs -A --context "$CONTEXT" -o jsonpath='{range .items[*]}{.metadata.name} {.status.replicas} {.status.availableReplicas} {.status.readyReplicas}{"\n"}{end}' | awk '$2 > 0 && ($2 != $3 || $2 != $4 || $3 != $4)'
