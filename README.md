# Objective/About 

* CloudBees HA/HS requires Controllers with EFS storage class.
* The  `./upgradeController.sh`script [automates the EBS/EFS steps describe here](https://docs.cloudbees.com/docs/cloudbees-ci/latest/ha-install-guide/install-ha-on-platforms#_migrate_an_existing_managed_controller_controller_to_high_availability_ha)
* The `./upgradeController.sh` script is about to upgrade a CB CI EBS Controller (StatefullSet) to EFS Controller (Deployment with Replicas)
* Inside the `yaml` directory you ll find some Kubernetes resource templates which are referenced during the migration by the upgrade script
* Inside the `script` directory you ll find some helper scripts, see the README files and resources there
* Inside the `test` directory you ll find some test Pipelines and test scripts for HA/HS. Some of them are in development state

# Get started

## Required tools referenced in the scripts

* aws-cli
* jq
* yq
* kubectl
* curl

## Note:

The availability zone `us-east-1a` is references in the scripts. 
If you are on another one, please replace it. 
* TODO: replace AZ with a variable

## Option 1: Upgrade Controller from EBS to EFS using a EBS Snapshot volume

* Using EBS Snapshots for the synchronization from EBS to EBS reduces the downtime of a Controller.
* It is useful for huge JENKINS_HOME volume sizes when Controller availability and less downtime is important.
* Use the `-e 1` parameter to trigger a sync from EBS snapshot

> ./upgradeController.sh -c YOUR_CONTROLLER_NAME  -e 1

Example
> ./upgradeController.sh -c team-ebs-controller1  -e 1

## Option 2: Upgrade Controller from EBS to EFS directly from a Controller PV volume (No EBS Snapshot)

* This will create an EFS PV and syncs the JENKINS_HOME data directly from the Controller PV volume
* Before the synchronization starts,the related  Kubernetes Statefulset of the Controller will be scaled to zero. 
* This causes a downtime of the Controller depending on the JENKINS_HOME size. 
* Use the `-e 0` parameter to skip a sync from EBS snapshot

> ./upgradeController.sh -c YOUR_CONTROLLER_NAME  -e 0

Example
> ./upgradeController.sh -c team-ebs-controller1  -e 0


# Final steps
* delete the Controller in CJOC and recreate it with the same name - Ensure efs-sc is applied in provisioning config
* for example you can use CasC: see [./scripts/createController/README.md](./scripts/createController/README.md) 
* Then enable HA on the controller
* To automate the final steps you can use CasC: see  [./scripts/createController/createManagedController.sh](./scripts/createController/createManagedController.sh)
* Example:  `cd scripts/createController/ && ./createManagedController.sh ${CONTROLLER_NAME} efs-sc"`



# Kubemetrics

To see CPU and Memory consumption of each Controller replica you need to install [kube-metrics](https://docs.aws.amazon.com/eks/latest/userguide/metrics-server.html)

```
watch kubectl top pod
```
Result
```
NAME                        CPU(cores)   MEMORY(bytes)
cjoc-0                      9m           1179Mi
ha-6dd96f6558-ckrxb         7m           1429Mi
ha-6dd96f6558-vrsvx         10m          1450Mi
```
