#!/bin/bash

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

# Get the list of all namespaces
namespaces=$(kubectl get ns --context "$CONTEXT" -o jsonpath='{.items[*].metadata.name}')

# List of namespaces to skip
skip_namespaces=("kube-system" "fluentd" "gatekeeper-system" "monitoring" "vmware-system-csi" "tigera-operator" "calico-system" "gravitee-dev" "gravitee-prod" "jenkins-dev" "jenkins-prod")

# Loop through each namespace
for ns in $namespaces; do

  # Check if the current namespace is in the skip list
  if [[ " ${skip_namespaces[@]} " =~ " ${ns} " ]]; then
    echo "Skipping namespace '$ns' as per predefined list."
    continue
  fi
  
  # Ask the user if they want to apply PSS for each namespace
  read -p "Apply PSS to namespace '$ns'? (y/N): " answer

  # Default answer to 'n' if user input is empty
  answer=${answer:-n}

  # If user says 'y', apply the label to the namespace
  if [[ "$answer" == "y" || "$answer" == "Y" ]]; then
    kubectl label ns "$ns" pod-security.kubernetes.io/enforce=restricted pod-security.kubernetes.io/enforce-version=latest pss-enforce="true" --context "$CONTEXT" --overwrite
    echo "Pod Security labels applied to namespace '$ns'."
  else
    echo "Skipped namespace '$ns'."
  fi
done

echo "Script completed."

