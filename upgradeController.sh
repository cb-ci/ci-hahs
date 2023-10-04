#! /bin/bash

set -euo pipefail

#The source Controller name
export DOMAIN=test-ebs1
export GENDIR=generated

mkdir -p $GENDIR
rm -Rf $GENDIR/*

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

echo "Create EBS snapshot and volume for $DOMAIN"
./scripts/createEBSSnapshotAndVolume.sh $DOMAIN
continueOrExit

echo "Backup existing Controller resources"
kubectl get statefulset  -l tenant=$DOMAIN -o yaml > $GENDIR/$DOMAIN-statefulset-source.yaml
kubectl get service      -l tenant=$DOMAIN -o yaml > $GENDIR/$DOMAIN-service-source.yaml
kubectl get ing          -l tenant=$DOMAIN -o yaml > $GENDIR/$DOMAIN-ing-source.yaml
kubectl get pvc          -l tenant=$DOMAIN -o yaml > $GENDIR/$DOMAIN-pvc-source.yaml
kubectl get pv $(kubectl get "pvc/jenkins-home-${DOMAIN}-0" -o go-template={{.spec.volumeName}}) -o yaml   > $GENDIR/$DOMAIN-pv-source.yaml
continueOrExit

export VOLUMEID=$(cat $GENDIR/ebs-snapshot_volume.json |jq -r  '.VolumeId')
echo "Create a new PV from the EBS snapshot volume with volume_id $VOLUMEID "
envsubst < yaml/pv-backup-jenkins-home-0.yaml  |kubectl apply -f -
continueOrExit

echo "Create a PVC wich clains the backup PV"
#kubectl get "pvc/jenkins-home-${DOMAIN}-0" -o yaml > yaml/pvc-backup-jenkins-home-${DOMAIN}-0.yaml
envsubst < yaml/pvc-backup-jenkins-home-0.yaml  |kubectl apply -f -
continueOrExit

#Alocate a backup job that uses the backup PVC (the wolume made from EBS snapshot))
envsubst < yaml/allocate-backup-jenkins-home-0.yaml |kubectl apply -f -
continueOrExit
kubectl wait --for=condition=complete job/allocate-backup-jenkins-home-${DOMAIN}-0
continueOrExit
kubectl delete job/allocate-backup-jenkins-home-${DOMAIN}-0
continueOrExit

#Create new volume with ReadWriteMany RWX
envsubst < yaml/pvc-rwx-jenkins-home-0.yaml |kubectl apply -f -
continueOrExit

#Test if we can claim the RWX volume
envsubst < yaml/allocate-rwx-jenkins-home-0.yaml |kubectl apply -f -
continueOrExit
kubectl wait --for=condition=complete job/allocate-rwx-jenkins-home-${DOMAIN}-0
continueOrExit
kubectl delete job/allocate-rwx-jenkins-home-${DOMAIN}-0

#The following two lines would sync directly from the existing jenkins-home-${DOMAIN}-0. If so a scale down is required before
#kubectl scale statefulsets/$DOMAIN --replicas=0
#./pvc-sync.sh jenkins-home-${DOMAIN}-0 pvc-rwx-jenkins-home-${DOMAIN}-0

echo "sync JENKINS_HOME data from backup-jenkins-home-${DOMAIN}-0 to the new RWX volume pvc-rwx-jenkins-home-${DOMAIN}-0"
./scripts/pvc-sync.sh backup-jenkins-home-${DOMAIN}-0 pvc-rwx-jenkins-home-${DOMAIN}-0
continueOrExit

#In case of EBS snapshot PV we need to scale down the Controller now
kubectl scale statefulsets/$DOMAIN --replicas=0
continueOrExit

#Replace the claimref and pv with the new volume (EFS/RWX)
./scripts/rename_pvc.sh pvc-rwx-jenkins-home-${DOMAIN}-0 jenkins-home-${DOMAIN}-0

echo "Next: delete the Controller in CJOC and recreate it with the same name- Ensure efs-sc is applied in provisioning  config"
echo "for example you can use CasC: see  ./scripts/createController/"
echo "Example:  ./scripts/createController/ && ./createManagedController.sh ${DOMAIN} efs-sc"
echo "Then enable HA on the controller"

