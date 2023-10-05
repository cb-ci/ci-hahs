# ci-hahs

This repo is about to upgrade a CB CI EBS Controller to EFS Controller
* Background see https://docs.cloudbees.com/docs/cloudbees-ci/latest/ha-install-guide/install-ha-on-platforms#_migrate_an_existing_managed_controller_controller_to_high_availability_ha

# Get started

## Upgrade Controller from EBS to EFS including EBS Snapshot volume
this will reduce the downtime of a Controller, useful for huge JENKINS_HOME volume sizes when Controller availability is important
> ./upgradeController.sh -c YOUR_CONTROLLER_NAME  -e 1

Example
> ./upgradeController.sh -c team-ebs-controller1  -e 1

## Upgrade Controller from EBS to EFS directly from Controller PV volume (No EBS Snapshot)
This will create a EFS PV and sync JENKINS_HOME data direcly from the Controller PV volume
Before the sync the statefulset of the Controller will be scaled to zero. 
This might increase the downtime ofthe Controller

> > ./upgradeController.sh -c YOUR_CONTROLLER_NAME  -e 0

Example
> ./upgradeController.sh -c team-ebs-controller1  -e 0



* Once the script is done, got to CJOC UI and delete the Controller.
 * * The original volume with JENKINS_HOME (EBS,RWO) will retain (see retain policy)
* Then recreate the Controller in CJOC with the same name. Ensure that the storage class in CJOC Controller config screen is pointing to an efs storage class before you start the new Controller
* CB CasC might help to avoid the manual steps 
* Once the Controller is up again it should have the data from the previous EBS JENKINS_HOME volume

