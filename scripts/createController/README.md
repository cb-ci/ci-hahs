TODO: add description
# Prepare

```
cp envvars.sh.template envvars.sh 
```


Then adjust your values in the envvars.sh file

# Delete Controller from Cjoc
Usage:

```
deleteController.sh <CONTROLLER_NAME> 
```


Examples

```
deleteController.sh test-controller-name
```


# Create Controller
Usage:

```
createManagedController.sh <CONTROLLER_NAME> <STORAGECLASS>
```


Examples
```
#Creates Controller with EBS Storagecalss (assuming gp2 is the EBS stroageclass) 
createManagedController.sh test-controller-name gp2
```

```
#Creates Controller with EBS Storagecalss (assuming efs-sc is the EBS stroageclass) 
createManagedController.sh test-controller-name efs-sc
```

# Recreate Controller with the same Name 

```
deleteController.sh test-controller-name
createManagedController.sh test-controller-name efs-sc
```
