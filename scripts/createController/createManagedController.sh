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


echo "------------------  CREATING MANAGED CONTROLLER ------------------"
curl -v \
   --user $TOKEN \
   "${CJOC_URL}/casc-items/create-items" \
    -H "Content-Type:text/yaml" \
   --data-binary @$GEN_DIR/${CONTROLLER_NAME}.yaml

#trap "rm -rf gen" EXIT