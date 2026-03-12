# Apply the policies
kubectl apply -f ./policies/

# Label namespaces to enforce policy
kubectl label namespace itsystems-lab pod-security.kubernetes.io/enforce=restricted pod-security.kubernetes.io/enforce-version=latest pss-enforce="true" --context calab

# OR use "apply-pss.sh" script in k8s-documentation repo to apply to all namespaces (with safe prompting)

# Or remove labels
kubectl label namespace itsystems-lab pod-security.kubernetes.io/enforce- pod-security.kubernetes.io/enforce-version- pss-enforce- --context calab

# TODO: Create a serviceAccount that is exempt from policy even if the namespace psp is enforced
kubectl create serviceaccount exempt-sa -n my-secure-namespace
kubectl annotate serviceaccount exempt-sa -n my-secure-namespace psp-exempt=true

# Rollout every deployment
kubectl get ns --context calab --no-headers -o custom-columns=:metadata.name | xargs -I{} kubectl rollout restart deployment --context calab --namespace {}

# Rollout every statefulset
kubectl get ns --context calab --no-headers -o custom-columns=:metadata.name | xargs -I{} kubectl rollout restart sts --context calab --namespace {}

# Rollout every daemonset
kubectl get ns --context calab --no-headers -o custom-columns=:metadata.name | xargs -I{} kubectl rollout restart ds --context calab --namespace {}

# Check all replicasets that have not successfully rolled out since it might be an issue in security policy change (in calab - adjust as necessary)
kubectl get rs -A --context calab -o jsonpath='{range .items[*]}{.metadata.name} {.status.replicas} {.status.availableReplicas} {.status.readyReplicas}{"\n"}{end}' | awk '$2 > 0 && ($2 != $3 || $2 != $4 || $3 != $4)'