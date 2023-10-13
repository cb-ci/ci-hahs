#! /bin/bash
TOKEN="user:token"
TOKEN="admin:111c3190e7c3adf2a0b6736858a235d91c"
#CONTROLLERNAME
CONTROLLER=ha #ADJUST ME
#CB BASE URL
CB_URL=https://ci.acaternberg.pscbdemos.com # ADJUST ME
CONTROLLER_URL=$CB_URL/$CONTROLLER
#JOBNAME
JOB=hellworld1




#first we need to create a test job
# see https://docs.cloudbees.com/docs/cloudbees-ci-kb/latest/client-and-managed-controllers/how-to-create-a-job-using-the-rest-api-and-curl
#CRUMB=$(curl -s -L -u $TOKEN $CONTROLLER_URL'/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,":",//crumb)')
#echo $CRUMB
#For CRUMB issues add the Header to the following curl requests
# -H "$CRUMB" -H "Content-Type:text/xml"
echo "Controller_url: $CONTROLLER_URL"
echo "Check if job exist"
if [ -n "$(curl -s -I -u $TOKEN -X GET $CONTROLLER_URL/job/$JOB/config.xml | grep -o  'HTTP/2 404')" ]
then
  echo "Testjob $JOB doesn't exist, let's create one"
  curl  -u $TOKEN -X POST \
    "$CONTROLLER_URL/createItem?name=$JOB" \
   --data-binary @testHooks-config.xml -H "Content-Type:text/xml"
fi

#then we build the job
#see https://docs.cloudbees.com/docs/cloudbees-ci-kb/latest/client-and-managed-controllers/how-to-build-a-job-using-the-rest-api-and-curl
# -H "$CRUMB" -H "Content-Type:text/xml"
while true
do
	echo "Press [CTRL+C] to stop.."
	curl  -u $TOKEN -X POST  $CONTROLLER_URL/job/$JOB/build
	sleep 1
done



