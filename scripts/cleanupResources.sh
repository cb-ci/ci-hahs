#! /bin/bash

#TODO, not tested
kubectl delete persistentvolumeclaim/backup-jenkins-home-$DOMAIN-0

kubectl delete persistentvolume/$(cat generated/old_pv)

VOLUMEID=$(cat $GENDIR/ebs-snapshot_volume.json |jq -r  '.VolumeId')
echo "deleting volume $VOLUMEID"
aws ec2 volume --volume-id $VOLUMEID
#trap "rm -rf generated" EXIT