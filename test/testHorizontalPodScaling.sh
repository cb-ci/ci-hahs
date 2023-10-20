#! /bin/bash
source ./setenv.sh
ADMINTOKEN="$CI_ADMIN_USER:$CI_ADMIN_TOKEN"
CONTROLLER_URL=$CI_BASE_URL/$CI_CONTROLLER
#see https://github.com/pipeline-demo-caternberg/pipeline-examples/blob/master/jobs/Jenkinsfile-stressController.groovy
JOB=stressController
curl   -s -IL  -u $ADMINTOKEN -X POST  "$CONTROLLER_URL/job/$JOB/build?delay=0sec&?token=$CI_ADMIN_TOKEN"
#kubectl get deployment $CONTROLLER
watch kubectl top pod -l com.cloudbees.cje.tenant=$CI_CONTROLLER