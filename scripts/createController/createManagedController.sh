#! /bin/bash

set -euo pipefail

if [ $# -lt 2 ]; then
  echo "Usage: $0 CONTROLLERNAME STORAGECLASS"
  echo "Example: $0 test-ebs gp2"
  exit 1
fi
source ./envvars.sh
export CONTROLLER_NAME=${1}
export CONTROLLER_URL=${BASE_URL}"/"${CONTROLLER_NAME}
export STORAGECLASS=${2}

GEN_DIR=gen
rm -rf $GEN_DIR
mkdir -p $GEN_DIR

# We render the CasC template instances for cjoc-controller-items.yaml  and the casc-folder (target folder)
# All variables from the envvars.sh will be substituted
envsubst < ${CREATE_MM_TEMPLATE_YAML} > $GEN_DIR/${CONTROLLER_NAME}.yaml

ALL_CONTROLLERS_JSON=allcontrollers.json

echo "Get all controllers to a local file gen/$ALL_CONTROLLERS_JSON"
curl -o gen/$ALL_CONTROLLERS_JSON -s  -u $TOKEN "$CJOC_URL/view/Controllers/api/json?depth=2&pretty=true" |jq

echo "Verify if $CONTROLLER_NAME controller exist"
#if [ -n $(cat gen/$ALL_CONTROLLERS_JSON |jq -c ".jobs[] | select( .name | contains($CONTROLLER_NAME))") ]
#then
#  echo "$CONTROLLER_NAME controller exist, will be deleted now from CJOC"
  PATH_CONTROLLER="job/$CONTROLLER_NAME"
  echo "force stop Controller $CONTROLLER_NAME"
  curl  -v -XPOST  -u $TOKEN "$CJOC_URL/$PATH_CONTROLLER/stopAction"
  sleep 10
  echo "delete Controller $CONTROLLER_NAME"
  curl  -v -XPOST -u $TOKEN "$CJOC_URL/$PATH_CONTROLLER/doDelete"
#fi

#echo "Verify if PVC jenkins-home-${CONTROLLER_NAME}-0 exist"
#if [ ! $(kubectl get pvc jenkins-home-${CONTROLLER_NAME}-0) ]
#then
#   #see https://docs.cloudbees.com/docs/cloudbees-ci-kb/latest/operations-center/how-to-delete-a-managed-controller-in-cloudbees-jenkins-enterprise-and-cloudbees-core
#   echo "PVC jenkins-home-$CONTROLLER_NAME-0 exist, will be deleted now"
#   kubectl delete pvc jenkins-home-$CONTROLLER_NAME-0
#fi

echo "------------------  CREATING MANAGED CONTROLLER ------------------"
echo "curl -v \
   --user $TOKEN \
   "${CJOC_URL}/casc-items/create-items" \
    -H "Content-Type:text/yaml" \
   --data-binary @$GEN_DIR/${CONTROLLER_NAME}.yaml"
curl -v \
   --user $TOKEN \
   "${CJOC_URL}/casc-items/create-items" \
    -H "Content-Type:text/yaml" \
   --data-binary @$GEN_DIR/${CONTROLLER_NAME}.yaml

#trap "rm -rf gen" EXIT