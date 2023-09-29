# ci-hahs

This repo is about to upgrade a CB CI EBS Controller to EFS Controller
* Background see https://docs.cloudbees.com/docs/cloudbees-ci/latest/ha-install-guide/install-ha-on-platforms#_migrate_an_existing_managed_controller_controller_to_high_availability_ha

# Get started
* set the variable DOMAIN in `upgradeController.sh` to your EBS controller name and run the script
* Once the script is done, got to CJOC UI and delete the Controller. 
* * The pvc with JENKINS_HOME (which have been updated in the first step) will retain (see retain policy)
* Then recreate the Controller in CJOC with the same name. Ensure that the storage class in CJOC Controller config screen is pointing to an efs storage class before you start the new Controller
* CB CasC might help to avoid the manual steps 
* Once the Controller is up again it should have the data from the previous EBS JENKINS_HOME volume

