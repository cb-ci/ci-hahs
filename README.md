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


# Final steps
* delete the Controller in CJOC and recreate it with the same name- Ensure efs-sc is applied in provisioning config
* for example you can use CasC: see  ./scripts/createController/README.md (./scripts/createController/README.md)
* Then enable HA on the controller

