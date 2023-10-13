#! /bin/bash

echo "Usage for time logging:$0 |while IFS= read -r line; do printf '+%s %s\n' "$(date)" "$line"; done| tee logger.log"
#CONTROLLERNAME
CONTROLLER=ha #ADJUST ME
#CB BASE URL
CB_URL=https://ci.acaternberg.pscbdemos.com # ADJUST ME
CONTROLLER_URL=$CB_URL/$CONTROLLER
#kubectl get deployments
checkOnline() {
  #kubectl rollout restart deployment $CONTROLLER
  RESPONSEHEADERS=headers1
  while [ -n "$(curl -s -IL ${CONTROLLER_URL}/login)" ]
  do
    curl  -IL -o ${RESPONSEHEADERS} ${CONTROLLER_URL}/login
    #cat $RESPONSEHEADERS
   if [ -n "$(cat $RESPONSEHEADERS |grep -E 'HTTP/2 201|HTTP/ 200')" ]
    then
      echo "${CONTROLLER_URL} is offline and not responding"
    fi
    echo "${CONTROLLER_URL} is online and responding"
    REPLICA="$(cat $RESPONSEHEADERS     |grep -E "x-jenkins-replica-host.*"    |  awk '{print $2}')"
    REPLICA_IP="$(cat $RESPONSEHEADERS  |grep -E "x-jenkins-replica-address.*" |  awk '{print $2}')"
    echo "REPLICA:   $REPLICA"
    #kubectl get pod -l com.cloudbees.cje.tenant=$CONTROLLER
    #kubectl rollout status deployment $CONTROLLER
    sleep 3
  done
}
checkOnline




