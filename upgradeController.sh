#! /bin/bash

set -euo pipefail

#The source Controller name
export CONTROLLER_NAME=${CONTROLLER_NAME:-"controller-ebs"}
#By default EBS snapshots are disabled -> ß
export WITH_EBS_SNAPSHOT=0

show_help (){
  echo "Usage: ${0##*/} -c <CONTROLLER_NAME> [OPTIONS]
          -h                display this help and exit
          -c controller     CONTROLLER_NAME
          -e                Do EBS Snapshot and sync from snapshot volume
        Example: ${0##*/} -c my-ebs-controller -e 1 # create an EBS snapshot volume (reduces the controller downtime)
        Example: ${0##*/} -c my-ebs-controller -e 0 # synchronize directly from jenkins_home pv, (increases the controller downtime)
     "
}


continueOrExit (){
  echo "Press 'y' to continue or 'n' to exit."
  read -s -n 1 key
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


if [[ ${#} -eq 0 ]]; then
   show_help
   exit 0
fi


OPTIND=1
# Resetting OPTIND is necessary if getopts was used previously in the script.
# It is a good idea to make OPTIND local if you process options in a function.
while getopts :h:e:c: opt; do
    case $opt in
        h)
            show_help
            exit 0
            ;;
        c)  CONTROLLER_NAME=$OPTARG
            ;;
        e)  WITH_EBS_SNAPSHOT=1
            ;;
        *)
            show_help >&2
            exit 1
            ;;
    esac
done
shift "$((OPTIND-1))"   # Discard the options and sentinel --

echo "CONTROLLER_NAME: $CONTROLLER_NAME"
echo "WITH_EBS_SNAPSHOT: $WITH_EBS_SNAPSHOT"

export GENDIR=generated
mkdir -p $GENDIR
rm -Rf $GENDIR/*

echo "Backup existing Controller resources"
continueOrExit
kubectl get statefulset  -l tenant=$CONTROLLER_NAME -o yaml > $GENDIR/$CONTROLLER_NAME-statefulset-source.yaml
kubectl get service      -l tenant=$CONTROLLER_NAME -o yaml > $GENDIR/$CONTROLLER_NAME-service-source.yaml
kubectl get ing          -l tenant=$CONTROLLER_NAME -o yaml > $GENDIR/$CONTROLLER_NAME-ing-source.yaml
kubectl get pvc          -l tenant=$CONTROLLER_NAME -o yaml > $GENDIR/$CONTROLLER_NAME-pvc-source.yaml
kubectl get pv $(kubectl get "pvc/jenkins-home-${CONTROLLER_NAME}-0" -o go-template={{.spec.volumeName}}) -o yaml   > $GENDIR/$CONTROLLER_NAME-pv-source.yaml

if [ $WITH_EBS_SNAPSHOT = 1 ]; then
  echo "Create EBS snapshot and volume for $CONTROLLER_NAME"
  continueOrExit
  ./scripts/createEBSSnapshotAndVolume.sh $CONTROLLER_NAME

  export VOLUMEID=$(cat $GENDIR/ebs-snapshot_volume.json |jq -r  '.VolumeId')
  echo "Create a new PV from the EBS snapshot volume with volume_id $VOLUMEID "
  envsubst < yaml/pv-backup-jenkins-home-0.yaml  |kubectl apply -f -

  echo "Create a PVC that clains the backup PV"
  #kubectl get "pvc/jenkins-home-${CONTROLLER_NAME}-0" -o yaml > yaml/pvc-backup-jenkins-home-${CONTROLLER_NAME}-0.yaml
  envsubst < yaml/pvc-backup-jenkins-home-0.yaml  |kubectl apply -f -

  echo "Allocate a backup job that uses the backup PVC (the volume that was made from EBS snapshot))"
  envsubst < yaml/allocate-backup-jenkins-home-0.yaml |kubectl apply -f -
  kubectl wait --for=condition=complete job/allocate-backup-jenkins-home-${CONTROLLER_NAME}-0
  kubectl delete job/allocate-backup-jenkins-home-${CONTROLLER_NAME}-0
fi

echo "Create new volume with ReadWriteMany RWX"
envsubst < yaml/pvc-rwx-jenkins-home-0.yaml |kubectl apply -f -

echo "Test if we can claim the RWX volume"
envsubst < yaml/allocate-rwx-jenkins-home-0.yaml |kubectl apply -f -
kubectl wait --for=condition=complete job/allocate-rwx-jenkins-home-${CONTROLLER_NAME}-0
kubectl delete job/allocate-rwx-jenkins-home-${CONTROLLER_NAME}-0

if [ $WITH_EBS_SNAPSHOT = 1 ]; then
    echo "sync JENKINS_HOME data from backup-jenkins-home-${CONTROLLER_NAME}-0 to the new RWX volume pvc-rwx-jenkins-home-${CONTROLLER_NAME}-0"
    #continueOrExit
    ./scripts/pvc-sync.sh backup-jenkins-home-${CONTROLLER_NAME}-0 pvc-rwx-jenkins-home-${CONTROLLER_NAME}-0
    echo "In case of EBS snapshot PV we need to scale down the Controller now"
    #continueOrExit
    kubectl scale statefulsets/$CONTROLLER_NAME --replicas=0
else
    echo "Scale down replicaset to zero and sync driectly from jenkins-home-${CONTROLLER_NAME}-0"
    #continueOrExit
    kubectl scale statefulsets/$CONTROLLER_NAME --replicas=0
    ./scripts/pvc-sync.sh jenkins-home-${CONTROLLER_NAME}-0 pvc-rwx-jenkins-home-${CONTROLLER_NAME}-0
fi

echo "Replace the claimref and pv with the new volume (EFS/RWX), then rename pvc-rwx-jenkins-home-${CONTROLLER_NAME}-0 to jenkins-home-${CONTROLLER_NAME}-0"
#continueOrExit
./scripts/rename_pvc.sh pvc-rwx-jenkins-home-${CONTROLLER_NAME}-0 jenkins-home-${CONTROLLER_NAME}-0

echo "Next: delete the Controller in CJOC and recreate it with the same name- Ensure efs-sc is applied in provisioning  config"
echo "for example you can use CasC: see  ./scripts/createController/createManagedController.sh"
echo "Example:  cd scripts/createController/ && ./createManagedController.sh ${CONTROLLER_NAME} efs-sc"
echo "Then enable HA on the controller"