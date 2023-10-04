#!/bin/bash
set -euo pipefail

if [ $# -lt 2 ]; then
  echo "Usage: $0 <source_pvc> <dest_pvc>"
  echo "Example: $0 backup-source-pvc new-volume-rwx"
  exit 1
fi
source_pvc="${1:?}"
dest_pvc="${2:?}"

if ! kubectl get "pvc/$source_pvc" -o name > /dev/null 2>&1; then
  echo "PVC $source_pvc does not exist."
  exit 1
fi

if ! kubectl get "pvc/$dest_pvc" -o name > /dev/null 2>&1; then
  echo "PVC $dest_pvc does not exist."
  exit 1
fi

if [ "$source_pvc" == "$dest_pvc" ]; then
  echo "Source and destination PVC must be different."
  exit 1
fi

echo "1. Migration step"
kubectl apply -f - <<JOB
apiVersion: batch/v1
kind: Job
metadata:
  name: migration
spec:
  template:
    metadata:
      annotations:
        cluster-autoscaler.kubernetes.io/safe-to-evict: "false"
    spec:
      volumes:
      - name: volume1
        persistentVolumeClaim:
          claimName: ${source_pvc}
      - name: volume2
        persistentVolumeClaim:
          claimName: ${dest_pvc}
      containers:
      - name: migration
        image: registry.access.redhat.com/ubi8/ubi
        command: [sh]
        args: [-c, "dnf install -y rsync; rsync -ruv --delete /var/volume1/ /var/volume2"]
        volumeMounts:
          - mountPath: /var/volume1
            name: volume1
          - mountPath: /var/volume2
            name: volume2
        resources:
          limits:
            cpu: "2"
            memory: 4G
          requests:
            cpu: "2"
            memory: 4G
      restartPolicy: Never
  backoffLimit: 4
JOB

echo "Waiting for migration to complete"
echo "You can inspect progress using kubectl logs -f job/migration"
echo "== Data from $source_pvc has been copied over to $dest_pvc"

