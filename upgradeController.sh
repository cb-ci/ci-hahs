#! /bin/bash

set -euo pipefail

#The source Controller name
export DOMAIN=test-ebs

continueOrExit (){
echo "Press 'y' to continue or 'n' to exit."
  # Wait for the user to press a key
  read -s -n 1 key
  # Check which key was pressed
  case $key in
      y|Y)
          echo "You pressed 'y'. Continuing..."
          ;;
      n|N)
          echo "You pressed 'n'. Exiting..."
          exit 1
          ;;
      *)
          echo "Invalid input. Please press 'y' or 'n'."
          ;;
  esac
}

#kubectl get pv $(kubectl get "pvc/jenkins-home-${DOMAIN}-0" -o go-template={{.spec.volumeName}}) -o yaml > pv-backup-jenkins-home-${DOMAIN}-0.yaml
#envsubst < pv-backup-jenkins-home-0.yaml  |kubectl apply -f -
#continueOrExit
#kubectl get "pvc/jenkins-home-${DOMAIN}-0" -o yaml > pvc-backup-jenkins-home-${DOMAIN}-0.yaml
#envsubst < pvc-backup-jenkins-home-0.yaml  |kubectl apply -f -
#continueOrExit
#envsubst < allocate-backup-jenkins-home-0.yaml |kubectl apply -f -
#continueOrExit
#kubectl wait --for=condition=complete job/allocate-backup-jenkins-home-${DOMAIN}-0
#continueOrExit
#kubectl delete job/allocate-backup-jenkins-home-${DOMAIN}-0
#continueOrExit

mkdir -p generated

#Backup existing Controller resources
kubectl get statefulset  -l tenant=$DOMAIN -o yaml > generated/$DOMAIN-statefulset-source.yaml
kubectl get service      -l tenant=$DOMAIN -o yaml > generated/$DOMAIN-service-source.yaml
kubectl get ing          -l tenant=$DOMAIN -o yaml > generated/$DOMAIN-ing-source.yaml
kubectl get pv           -l tenant=$DOMAIN -o yaml > generated/$DOMAIN-pv-source.yaml
kubectl get pvc          -l tenant=$DOMAIN -o yaml > generated/$DOMAIN-pvc-source.yaml

#In case of EBS we need to scale down the Controller because of Multi-attach ReadWriteOnce is not supported
kubectl scale statefulsets/$DOMAIN --replicas=0
continueOrExit

#Create new volume with ReadWriteMany RWX
envsubst < pvc-rwx-jenkins-home-0.yaml |kubectl apply -f -
continueOrExit

#Test if we can claim the RWX volume
envsubst < allocate-rwx-jenkins-home-0.yaml |kubectl apply -f -
continueOrExit
kubectl wait --for=condition=complete job/allocate-rwx-jenkins-home-${DOMAIN}-0
continueOrExit
kubectl delete job/allocate-rwx-jenkins-home-${DOMAIN}-0

#Sync JENKINS_HOME data to the new RWX volume
./pvc-sync.sh jenkins-home-${DOMAIN}-0 pvc-rwx-jenkins-home-${DOMAIN}-0
kubectl wait --for=condition=complete --timeout=900m job/migration
kubectl delete job migration
continueOrExit
#Replace the claimref and pv with the new volume (EFS/RWX)
./rename_pvc.sh pvc-rwx-jenkins-home-${DOMAIN}-0 jenkins-home-${DOMAIN}-0

#Next: delete the Controller in CJOC and recreate it with the same name- Ensure efs-sc is applied in provisioning  config
# Then enable HA

