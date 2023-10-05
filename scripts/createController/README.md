TODO: add description
# Prepare
> cp envvars.sh.template envvars.sh 

Then adjust your values in the envvars.sh file

# Delete Controller from Cjoc
Usage:
> deleteController.sh <CONTROLLER_NAME> 

Examples
> deleteController.sh test-controller-name
> createManagedController.sh test-controller-name efs-sc

# Create Controller
Usage:
> cp envvars.sh.template envvars.sh #Adjust your values 
> createManagedController.sh <CONTROLLER_NAME> <STORAGECLASS>

Examples
> createManagedController.sh test-controller-name gp2
> createManagedController.sh test-controller-name efs-sc


# Recreate Controller with the same Name 

> deleteController.sh test-controller-name
> createManagedController.sh test-controller-name efs-sc