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