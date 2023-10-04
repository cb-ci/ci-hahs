#!/bin/bash
set -euo pipefail

if [ $# -ne 2 ]; then
  echo "Usage: $0 source_pvc dest_pvc"
  exit 1
fi
#domain="${1:?}"
source_pvc=$1
dest_pvc=$2

mkdir -p generated/patch

if ! kubectl get "pvc/$source_pvc" -o name > /dev/null 2>&1; then
  echo "PVC $source_pvc does not exist."
  exit 1
fi

if kubectl get "pvc/$dest_pvc" -o name > /dev/null 2>&1; then
  echo "PVC $dest_pvc already exists. It will be replaced by persistent volume of $source_pvc."
  read -p "Are you sure? " -n 1 -r
  # Delete PVC-1, keep PV as backup
  pv1_name=$(kubectl get "pvc/${dest_pvc}" -o go-template={{.spec.volumeName}})
  echo "$pv1_name" > generated/old_pv
  echo "== ${dest_pvc} points to pv/${pv1_name}"
  kubectl patch pv ${pv1_name} -p '{"spec": {"persistentVolumeReclaimPolicy": "Retain"}}'
  echo "Deleting ${dest_pvc}, we keep PV ${pv1_name} around"
  kubectl delete pvc/${dest_pvc}
  #kubectl patch pv ${pv1_name} -p '{"spec":{"claimRef": null}}'
fi


# Rename pvc-2 to pvc-1
# Change PV RetainPolicy to "Retain"

pv_name=$(kubectl get "pvc/${source_pvc}" -o go-template={{.spec.volumeName}})
echo "== ${source_pvc} points to pv/${pv_name}"
kubectl get "pvc/${source_pvc}" -o yaml > generated/patch/source_pvc.yaml
kubectl patch pv ${pv_name} -p '{"spec": {"persistentVolumeReclaimPolicy": "Retain"}}'
kubectl delete "pvc/${source_pvc}"
kubectl patch pv ${pv_name} -p '{"spec":{"claimRef": null}}'

# We ideally want to retain any user annotation
cat <<EOF >generated/patch/patch.yaml
- op: replace
  path: /metadata/name
  value: ${dest_pvc}
- op: replace
  path: /spec/volumeName
  value: ${pv_name}
- op: remove
  path: /metadata/finalizers
- op: remove
  path: /metadata/creationTimestamp
- op: remove
  path: /metadata/namespace
- op: remove
  path: /metadata/resourceVersion
- op: remove
  path: /metadata/uid
- op: remove
  path: /status
EOF

cat <<EOF >generated/patch/kustomization.yaml
patches:
 - target:
      version: v1
      kind: PersistentVolumeClaim
      name: ${source_pvc}
   path: patch.yaml
resources:
- source_pvc.yaml
EOF

kubectl apply -k generated/patch
pv_name=$(kubectl get pvc/${dest_pvc} -o go-template={{.spec.volumeName}})
echo "== ${dest_pvc} points to pv/${pv_name}"
echo "== Resetting ${pv_name} retain policy to Delete"
kubectl patch pv ${pv_name} -p '{"spec": {"persistentVolumeReclaimPolicy": "Delete"}}'
