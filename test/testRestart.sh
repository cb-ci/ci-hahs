#! /bin/bash

source ./setenv.sh
CONTROLLER_URL=$CI_BASE_URL/$CI_CONTROLLER
curl  -s -IL   -u "$CI_ADMIN_USER:$CI_ADMIN_TOKEN" ${CONTROLLER_URL}/restart
./testControllerIsOnline.sh


