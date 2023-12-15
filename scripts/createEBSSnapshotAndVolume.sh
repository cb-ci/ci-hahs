#! /bin/bash

DOMAIN=${1:-"test-ebs"}

export GENDIR=generated

mkdir -p $GENDIR
export AWS_DEFAULT_REGION=us-east-1

TAGS="ResourceType=snapshot,Tags=[{Key=cb-environment,Value=cihahs-test},{Key=cb-user,Value=YOURUSER},{Key=cb-owner,Value=YOURDEPARTMENT}]"

#The JENKINS_HOME PV name where we want to take a snapshot from
VOLUMENAME=$(kubectl get "pvc/jenkins-home-${DOMAIN}-0" -o go-template={{.spec.volumeName}})
#The volume id of the PV
VOLUMEID=$(kubectl get pv $VOLUMENAME -o go-template={{.spec.awsElasticBlockStore.volumeID}})

echo "take snapshot for $DOMAIN, $VOLUMENAME, $VOLUMEID"
SNAPSHOT=$(aws ec2 create-snapshot \
--volume-id "$VOLUMEID" \
--description "$DOMAIN,$VOLUMENAME,$VOLUMEID" \
--output json \
--tag-specifications $TAGS)
echo $SNAPSHOT |jq  >  $GENDIR/ebs-snapshot.json

SNAPSHOTID=$(cat $GENDIR/ebs-snapshot.json |jq -r '.SnapshotId')
aws ec2 wait snapshot-completed \
    --snapshot-ids $SNAPSHOTID
echo "snapshot $SNAPSHOTID created"

echo "create volume for $SNAPSHOTID"
#--tag-specifications $TAGS \
SNAPSHOT_VOLUME=$(aws ec2 create-volume \
--volume-type gp2 \
--snapshot-id $SNAPSHOTID \
--availability-zone us-east-1a \
--output json)
echo $SNAPSHOT_VOLUME |jq  >  $GENDIR/ebs-snapshot_volume.json
export VOLUMEID=$(cat $GENDIR/ebs-snapshot_volume.json |jq -r  '.VolumeId')
echo "volume $VOLUMEID created"

echo "delete snapshot $SNAPSHOTID, we don't need it anymore"
aws ec2 delete-snapshot --snapshot-id $SNAPSHOTID