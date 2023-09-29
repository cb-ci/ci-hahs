#! /bin/bash
#CONTROLLERNAME
CONTROLLER=ha #ADJUST ME
#CB BASE URL
CB_URL=https://<CB_BASE_URL> # ADJUST ME
CONTROLLER_URL=$CB_URL/$CONTROLLER
kubectl get deployments
#kubectl rollout restart deployment $CONTROLLER
while [ -n "$(curl  -sIL  ${CONTROLLER_URL}/login | grep -o  'HTTP/2 200')" ]
do
  echo "${CONTROLLER_URL} is online and responding"
  kubectl get pod -l com.cloudbees.cje.tenant=$CONTROLLER
  #kubectl rollout status deployment $CONTROLLER
  sleep 3
done
echo "${CONTROLLER_URL} is offline and not responding"



