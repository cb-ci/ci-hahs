#! /bin/bash
set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Usage: $0 CONTROLLERNAME"
  echo "Example: $0 test-ebs"
  exit 1
fi
source ./envvars.sh
export CONTROLLER_NAME=${1}
export CONTROLLER_URL=${BASE_URL}"/"${CONTROLLER_NAME}


ALL_CONTROLLERS_JSON=allcontrollers.json

echo "Get all controllers to a local file gen/$ALL_CONTROLLERS_JSON"
curl -o gen/$ALL_CONTROLLERS_JSON -s  -u $TOKEN "$CJOC_URL/view/Controllers/api/json?depth=2&pretty=true" |jq

echo "Verify if $CONTROLLER_NAME controller exist"
CONTROLLER_EXIST=$(cat gen/$ALL_CONTROLLERS_JSON |jq -c '.jobs[] | select( .name | contains($ARGS.positional[0]))' --args $CONTROLLER_NAME)
echo $CONTROLLER_EXIST
if [ -n "$CONTROLLER_EXIST" ]
then
  echo "$CONTROLLER_NAME controller exist, will be deleted now from CJOC"
  PATH_CONTROLLER="job/$CONTROLLER_NAME"
  echo "force stop Controller $CONTROLLER_NAME"
  curl   -XPOST -L -s  -u $TOKEN $CJOC_URL/$PATH_CONTROLLER/stopAction
  sleep 10
  echo "delete Controller $CONTROLLER_NAME"
  curl   -XPOST -L -s -u $TOKEN "$CJOC_URL/$PATH_CONTROLLER/doDelete"
fi

echo "Verify if PVC jenkins-home-${CONTROLLER_NAME}-0 exist"
if ! kubectl get "pvc/jenkins-home-${CONTROLLER_NAME}-0)" -o name > /dev/null 2>&1; then
   #see https://docs.cloudbees.com/docs/cloudbees-ci-kb/latest/operations-center/how-to-delete-a-managed-controller-in-cloudbees-jenkins-enterprise-and-cloudbees-core
   echo "PVC jenkins-home-$CONTROLLER_NAME-0 exist, will be deleted now"
   kubectl delete pvc jenkins-home-$CONTROLLER_NAME-0
fi