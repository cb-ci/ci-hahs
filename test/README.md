# Prepare config

```
cp setenv.sh.rename setenv.sh
```
* Set your values in `setenv.sh`

# Tests

## testJobTrigger.sh 

tests whether we can access the API and trigger a Job.
* Each build is always running on the same replica
* If the current replicate gets interrupted the build resumes on the next replica. If agents are used, they will be reconnected to another replica, in case the replica het interrupted or deleted


# Run with Time logging

To enable time logging we need to add the following to the end of the script calls 
>  |while IFS= read -r line; do printf '%s %s\n' "$(date)" "$line"; done |tee logger.log"

For example
> ./testJobTrigger.sh |while IFS= read -r line; do printf '%s %s\n' "$(date)" "$line"; done |tee logger.log


# Horiontal podscaling

see https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale-walkthrough/ 
> kubectl autoscale deployment ha  --cpu-percent=50 --min=2 --max=3
> kubectl delete hpa ha
> kubectl scale --replicas=3 deployment/ha

# Run API test

```
cp setenv.sh.rename setenv.sh
source ./setenv.sh
./testAPI.sh $CI_ADMIN_TOKEN $CI_BASE_URL $CI_CONTROLLER
```



# Stress Controller 

see https://github.com/pipeline-demo-caternberg/pipeline-examples/blob/master/jobs/Jenkinsfile-stressController.groovy