#!/bin/bash

set -e

KUBERNETES_VERSION=1.28.15  #Next version 1.27.16 #prev version 1.26.15 #really future: 1.28.15
CNI_PLUGINS_VERSION=v1.6.0
CONTAINERD_VERSION=1.7.23
CRICTL_VERSION=v1.29.0
KREL_VERSION=v0.17.10
RUNC_VERSION=v1.1.15
ARCH=amd64

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

MASTER_LIST=$(kubectl get nodes --context "$CONTEXT" --selector='node-role.kubernetes.io/control-plane' --no-headers | grep -v "$KUBERNETES_VERSION" | awk '{print $1}')

# Create a local temp dir
PACKAGES_DIR=$(mktemp -d)
echo Downloading packages to $PACKAGES_DIR

# Download the packages to the temp dir
(cd "${PACKAGES_DIR}" && \
    curl -L --remote-name-all "https://github.com/containernetworking/plugins/releases/download/${CNI_PLUGINS_VERSION}/cni-plugins-linux-${ARCH}-${CNI_PLUGINS_VERSION}.tgz" && \
    curl -L --remote-name-all "https://github.com/kubernetes-sigs/cri-tools/releases/download/${CRICTL_VERSION}/crictl-${CRICTL_VERSION}-linux-${ARCH}.tar.gz" && \
    curl -L --remote-name-all "https://dl.k8s.io/release/v${KUBERNETES_VERSION}/bin/linux/${ARCH}/kubeadm" && \
    curl -L --remote-name-all "https://dl.k8s.io/release/v${KUBERNETES_VERSION}/bin/linux/${ARCH}/kubelet" && \
    curl -L --remote-name-all "https://dl.k8s.io/release/v${KUBERNETES_VERSION}/bin/linux/${ARCH}/kubectl" && \
    curl -L --remote-name-all "https://github.com/containerd/containerd/releases/download/v${CONTAINERD_VERSION}/containerd-${CONTAINERD_VERSION}-linux-${ARCH}.tar.gz" && \
    curl -L --remote-name-all "https://raw.githubusercontent.com/containerd/containerd/main/containerd.service" && \
    curl -L "https://github.com/opencontainers/runc/releases/download/${RUNC_VERSION}/runc.${ARCH}" -o runc && \
    curl -sSL "https://raw.githubusercontent.com/kubernetes/release/${KREL_VERSION}/cmd/krel/templates/latest/kubelet/kubelet.service" -o kubelet.service && \
    curl -sSL "https://raw.githubusercontent.com/kubernetes/release/${KREL_VERSION}/cmd/krel/templates/latest/kubeadm/10-kubeadm.conf" -o 10-kubeadm.conf)

# Create the creds source file and passphrase
PASSPHRASE=$(openssl rand -base64 24 | tr -dc 'a-zA-Z0-9' | head -c32)
echo Generated unique passphrase: $PASSPHRASE
CRED_FILE="${PACKAGES_DIR}/cred"
echo "export REMOTE_PASSWORD=\"${password}\"" | openssl enc -pbkdf2 -base64 -pass pass:$PASSPHRASE > $CRED_FILE
chmod 400 $CRED_FILE

# Create the upgrade script
UPGRADE_SCRIPT="${PACKAGES_DIR}/upgrade.sh"

cat <<EOF > "$UPGRADE_SCRIPT"
#!/bin/bash

set -e

export PATH=/opt/app/containerd/bin:/opt/app/kubernetes/bin:\$PATH

# 1. Install the CNI plugins
tar -C "${DEST}" -xzf ${PACKAGES_DIR}/cni-plugins-linux-${ARCH}-${CNI_PLUGINS_VERSION}.tgz

# 2. Install crictl
tar -C "${K8S_BIN_DIR}" -xzf ${PACKAGES_DIR}/crictl-${CRICTL_VERSION}-linux-${ARCH}.tar.gz

# 3. Install kubeadm
yes | cp ${PACKAGES_DIR}/kubeadm ${K8S_BIN_DIR} && chmod +x ${K8S_BIN_DIR}/kubeadm

# 4. Install kubectl
yes | cp ${PACKAGES_DIR}/kubectl ${K8S_BIN_DIR} && chmod +x ${K8S_BIN_DIR}/kubectl

# 5. Install the Kubernetes RELease tooling and infrastructure (systemd files)
sed "s:/usr/bin:${K8S_BIN_DIR}:g" ${PACKAGES_DIR}/kubelet.service | tee /etc/systemd/system/kubelet.service
sed "s:/usr/bin:${K8S_BIN_DIR}:g" ${PACKAGES_DIR}/10-kubeadm.conf | tee /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
systemctl daemon-reload

# Loop until kubeadm and kubectl are the right versions
while true; do
    set +e  # Disable exit on error temporarily

    ${K8S_BIN_DIR}/kubeadm version | grep -q $KUBERNETES_VERSION
    KUBEADM_STATUS=\$?
    ${K8S_BIN_DIR}/kubectl version --client | grep -q $KUBERNETES_VERSION
    KUBECTL_STATUS=\$?

    set -e

    if [ \$KUBEADM_STATUS -eq 0 ] && [ \$KUBECTL_STATUS -eq 0 ]; then
        echo "Kubeadm and kubectl components match the desired Kubernetes version: $KUBERNETES_VERSION"
        break
    else
        echo "Components do not match the desired version yet. If this continues forever, try manually replacing the binaries. Retrying..."
        sleep 5
    fi
done

# 6. If it's the first master, do the actual cluster upgrade, otherwise just upgrade the node
if [[ \$(hostname) == *medk8ma01.medimpact.com ]]; then
    echo "This is the first master. Will upgrade the cluster!"
    ${K8S_BIN_DIR}/kubeadm upgrade plan
    ${K8S_BIN_DIR}/kubeadm upgrade apply ${KUBERNETES_VERSION} -y
else
    echo "This is not the first master. Upgrading node only."
    ${K8S_BIN_DIR}/kubeadm upgrade node
fi

# 7. Upgrade the kubelet
systemctl stop kubelet
yes | cp ${PACKAGES_DIR}/kubelet ${K8S_BIN_DIR} && chmod +x ${K8S_BIN_DIR}/kubelet
systemctl start kubelet

# Loop until the kubelet is the right version
while true; do
    set +e
    
    ${K8S_BIN_DIR}/kubelet --version | grep -q $KUBERNETES_VERSION
    KUBELET_STATUS=\$?

    set -e

    if [ \$KUBEADM_STATUS -eq 0 ] && [ \$KUBELET_STATUS -eq 0 ] && [ \$KUBECTL_STATUS -eq 0 ]; then
        echo "All components match the desired Kubernetes version: $KUBERNETES_VERSION"
        break
    else
        echo "Components do not match the desired version yet. If this continues forever, try manually replacing the binaries. Retrying..."
        sleep 5
    fi
done

EOF



# Create the patch script
PATCH_SCRIPT="${PACKAGES_DIR}/patch.sh"
cat <<EOF > "$PATCH_SCRIPT"
#!/bin/bash

set -e

export PATH=/opt/app/containerd/bin:/opt/app/kubernetes/bin:\$PATH

systemctl stop kubelet
systemctl stop containerd

tar -C /opt/app/containerd -xzf ${PACKAGES_DIR}/containerd-${CONTAINERD_VERSION}-linux-${ARCH}.tar.gz

systemctl daemon-reload
systemctl start containerd

${K8S_BIN_DIR}/crictl rmi --prune

systemctl stop containerd
sleep 5
bash -c "rm -rf /opt/app/containerd/var/* || true"
yum upgrade -y
shutdown -r +1
EOF

chmod +x "$UPGRADE_SCRIPT"
chmod +x "$PATCH_SCRIPT"

# Upgrade the cluster and k8s components on each master
while read server <&3; do
    echo "Upgrading $server"

    echo "Copying packages in ${PACKAGES_DIR} to $server"
    
    # Copy the packages to the remote server
    sshpass -p "$password" scp -r -q -o StrictHostKeyChecking=no "${PACKAGES_DIR}" "$username@$server:${PACKAGES_DIR}"
    
    # Decrypt the creds
    DECRED_FILE="${PACKAGES_DIR}/cred.de"
    sshpass -p "$password" ssh -t -t -q -o StrictHostKeyChecking=no "$username@$server" "cat $CRED_FILE | openssl enc -pbkdf2 -base64 -d -pass pass:$PASSPHRASE > ${DECRED_FILE} && chmod 400 ${DECRED_FILE}"
    
    # Execute the script to upgrade the cluster
    sshpass -p "$password" ssh -t -t -q -o StrictHostKeyChecking=no "$username@$server" "source ${DECRED_FILE} && printf '%s\n' \"\$REMOTE_PASSWORD\" | sudo -S bash ${UPGRADE_SCRIPT}"

    secs=$((1 * 10))
    while [ $secs -gt 0 ]; do
        echo -ne "$server complete. Upgrading next node in $secs seconds\033[0K\r"
        sleep 1
        : $((secs--))
    done
done 3<<<"$MASTER_LIST"


# Drain each master and patch and reboot
while read server <&3; do
    echo "patching $server"

    kubectl drain "$server" --ignore-daemonsets --delete-emptydir-data --force --grace-period=120 --context "$CONTEXT"
    
    # Execute the script to patch the masters.
    sshpass -p "$password" ssh -t -t -q -o StrictHostKeyChecking=no "$username@$server" "source ${DECRED_FILE} && printf '%s\n' \"\$REMOTE_PASSWORD\" | sudo -S bash ${PATCH_SCRIPT}"
    
    until sshpass -p "$password" ssh -t -t -q -o StrictHostKeyChecking=no "$username@$server" "source $DECRED_FILE && printf '%s\n' \"\$REMOTE_PASSWORD\" | sudo -S systemctl is-active --quiet kubelet"; do
        echo -ne "Waiting for $server and its kubelet to restart.\033[0K\r"
        sleep 5
    done

    echo "Kubelet is active on $server. Waiting for critical control plane components to be ready."

    #kubectl rollout status -n kube-system ds/kube-proxy --context "$CONTEXT"
    kubectl rollout status -n kube-system ds/calico-node --context "$CONTEXT"
    kubectl rollout status -n vmware-system-csi ds/vsphere-csi-node --context "$CONTEXT"
    kubectl uncordon "$server" --context "$CONTEXT"
      
    # Delete the packages on the server
    sshpass -p "$password" ssh -t -t -q -o StrictHostKeyChecking=no "$username@$server" "rm -rf ${PACKAGES_DIR} || true"

    secs=$((1 * 10))
    while [ $secs -gt 0 ]; do
        echo -ne "$server complete. Patching next node in $secs seconds\033[0K\r"
        sleep 1
        : $((secs--))
    done
done 3<<<"$MASTER_LIST"

# Clean up the temporary script
rm -rf "${PACKAGES_DIR}"
