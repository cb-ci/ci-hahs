#! /bin/bash
TOKEN="YOUADMINTOKEN"
ADMINTOKEN="admin:$TOKEN"
#CONTROLLERNAME
CONTROLLER=ha #ADJUST ME
#CB BASE URL
CB_URL=https://ci.acaternberg.pscbdemos.com # ADJUST ME
CONTROLLER_URL=$CB_URL/$CONTROLLER
#JOBNAME
JOB=hellworld

#first we need to create a test job
# see https://docs.cloudbees.com/docs/cloudbees-ci-kb/latest/client-and-managed-controllers/how-to-create-a-job-using-the-rest-api-and-curl
#CRUMB=$(curl -s -L -u $TOKEN $CONTROLLER_URL'/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,":",//crumb)')
#echo $CRUMB
#For CRUMB issues add the Header to the following curl requests
# -H "$CRUMB" -H "Content-Type:text/xml"
echo "Controller_url: $CONTROLLER_URL"
echo "Check if job exist"
if [ -n "$(curl  -s -IL -u $ADMINTOKEN -X GET $CONTROLLER_URL/job/$JOB/config.xml | grep -o  'HTTP/2 404')" ]
then
  echo "Testjob $JOB doesn't exist, let's create one"
  curl -L -s -u $ADMINTOKEN "$CONTROLLER_URL/createItem?name=$JOB"   --data-binary @helloworld-Job-config.xml -H "Content-Type:text/xml"
fi

#then we build the job
#see https://docs.cloudbees.com/docs/cloudbees-ci-kb/latest/client-and-managed-controllers/how-to-build-a-job-using-the-rest-api-and-curl
# -H "$CRUMB" -H "Content-Type:text/xml"
while true
do
 	echo "#######################################"
	echo "start build of Job: $JOB"
	#curl -i -u $TOKEN -X POST  $CONTROLLER_URL/job/$JOB/build
	#RESPONSE=$(curl  -si -w "\n%{size_header},%{size_download}" -u $TOKEN -X POST  $CONTROLLER_URL/job/$JOB/build)
	#see curl headers https://daniel.haxx.se/blog/2022/03/24/easier-header-picking-with-curl/
  RESPONSEHEADERS=headers
  #-b cookie-jar.txt
	curl -s -IL -o $RESPONSEHEADERS  -u $ADMINTOKEN -X POST  "$CONTROLLER_URL/job/$JOB/build?delay=0sec&?token=$TOKEN"
  #cat $RESPONSEHEADERS
  if [ -z "$(cat $RESPONSEHEADERS |grep -oE 'HTTP/2 201|HTTP/ 200')" ]
  then
      echo "Can not create job, Gateway/Endpoint not available with HTTP state:  $(cat $RESPONSEHEADERS |grep 'HTTP/2') "
      #exit 1
	else
	    LOCATION="$(cat $RESPONSEHEADERS    |grep -E "location.*"                  |  awk '{print $2}')"
	    REPLICA="$(cat $RESPONSEHEADERS     |grep -E "x-jenkins-replica-host.*"    |  awk '{print $2}')"
	    REPLICA_IP="$(cat $RESPONSEHEADERS  |grep -E "x-jenkins-replica-address.*" |  awk '{print $2}')"
	    echo "LOCATION:  $LOCATION"
	    echo "REPLICA:   $REPLICA"
	    #curl -u $TOKEN  -IL $LOCATION/api/json?pretty=true
	fi
	sleep 10
done



