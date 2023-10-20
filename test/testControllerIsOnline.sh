#! /bin/bash

#echo "Usage for time logging:$0 |while IFS= read -r line; do printf '%s %s\n' "\$(date)" "\$line"; done| tee logger.log"

source ./setenv.sh

#CB BASE URL
CI_CONTROLLER_URL=$CI_BASE_URL/$CI_CONTROLLER
LIVENESS_PROBE_URI=/whoAmI/api/json?tree=authenticated
CONNECT_TIMEOUT=5
#kubectl get deployments
checkOnline() {
  #kubectl rollout restart deployment $CI_CONTROLLER
  RESPONSEHEADERS=headers-CI_CONTROLLER-online
  while [ -n "$(curl --connect-timeout $CONNECT_TIMEOUT  -s -IL ${CI_CONTROLLER_URL}/$LIVENESS_PROBE_URI)" ]
  do
    echo "##################################################"
    curl --connect-timeout  $CONNECT_TIMEOUT  -s -IL -o ${RESPONSEHEADERS} ${CI_CONTROLLER_URL}/$LIVENESS_PROBE_URI
    #cat $RESPONSEHEADERS
    if [ -n "$(cat $RESPONSEHEADERS |grep -E 'HTTP/2 201|HTTP/ 200')" ]
    then
      echo "${CI_CONTROLLER_URL} is offline and not responding"
    fi
    echo "${CI_CONTROLLER_URL} is online and responding"
    REPLICA="$(cat $RESPONSEHEADERS     |grep -E "x-jenkins-replica-host.*"    |  awk '{print $2}')"
    REPLICA_IP="$(cat $RESPONSEHEADERS  |grep -E "x-jenkins-replica-address.*" |  awk '{print $2}')"
    echo "REPLICA:      $REPLICA"
    echo "REPLICA_IP:   $REPLICA_IP"
    #kubectl get pod -l com.cloudbees.cje.tenant=$CI_CONTROLLER
    #kubectl rollout status deployment $CI_CONTROLLER
    sleep $CONNECT_TIMEOUT
  done
  echo "${CI_CONTROLLER_URL} is offline and not responding"

}
checkOnline




