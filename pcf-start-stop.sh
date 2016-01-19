#!/bin/bash
# Set for 1.5.x Jobs

export BUNDLE_GEMFILE=/home/tempest-web/tempest/web/bosh.Gemfile
if [ "$1" == "shut" ] || [  "$1" == "start" ];
        then
                echo "Running PCF $1 Process..."
        else
                echo "Only shut or start are valid args!"
                exit 1
fi


declare -a bootOrder=(
nats
consul_server
etcd_server
nfs_server
ccdb
uaadb
consoledb
cloud_controller
ha_proxy
router
health_manager
clock_global
cloud_controller_worker
uaa
mysql_proxy
mysql
dea
diego_brain
diego_cell
diego_database
doppler
loggregator_trafficcontroller
)


if [ "$1" == "shut" ]; then
 jobVMs=$(bundle exec bosh vms --detail|grep partition| awk -F '|' '{ print $2 }')
 bundle exec bosh vm resurrection disable
 for (( i=${#bootOrder[@]}-1; i>=0; i-- )); do
        for x in $jobVMs; do
                jobId=$(echo "$x" | awk -F "/" '{ print $1 }')
                instanceId=$(echo "$x" | awk -F "/" '{ print $2 }')
                jobType=$(echo "$jobId" | awk -F "-" '{ print $1 }')
                        if [ "$jobType" == "${bootOrder[$i]}" ];
                        then
                                #echo MATCHVAL---${bootOrder[$i]} JOBTYPE----$jobType JOBID----$jobId Instance-------$instanceId
                                bundle exec bosh -n stop "${jobId}"  "${instanceId}" --hard
                        fi
        done;

 done
fi


if [ "$1" == "start" ]; then
 startJobVMs=$(bundle exec bosh vms --detail  | grep partition | awk -F '|' '{ print $2 }')
 bundle exec bosh vm resurrection enable
 for i in "${bootOrder[@]}"; do
        for x in $startJobVMs; do
                jobId=$(echo "$x" | awk -F "/" '{ print $1 }')
                instanceId=$(echo "$x" | awk -F "/" '{ print $2 }')
                jobType=$(echo "$jobId" | awk -F "-" '{ print $1 }')
                 if [ "$i" == "$jobType" ];
                 then
                        #echo FOUND "$jobId" instanceID "$instanceId"
                        bundle exec bosh -n start "$jobId" "$instanceId"
                 fi
        done;
 done
fi


