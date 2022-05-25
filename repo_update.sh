#!/bin/bash

#Set in repo_maintenance.incron & repo_cleanup.cron with repo_update $@ ep-server
debianPackageLocation=$1 #Directory with debian packages
repoName=$2 #Name of aptly repository
distribution=$3 #Distribution to update on endpoint

endpointPrefix=filesystem:$repoName: #Endpoint and prefix [[<endpoint>:]<prefix>] where repo is published (/etc/aptly.conf)

#Set name for new snapshot
date=`date +%Y-%m-%d_%H%M%S` #Current date
snapshotName=$date #Name of snaphot to be created

#Write logs
logFile=/var/log/aptly/repo_maintenance.log
write_logdate () {
    echo "-- `date` --" >> $logFile
}
write_logdate
echo "-- Running $0 --" >> $logFile

#Error handling
error=0
exit_on_error () {
    error=$?
    if [ $error -ne 0 ]
    then
     exit $error
    fi
}

if [ $# -eq 0 ]
  then
    write_logdate
    echo "No arguments supplied. Specify path to directory with debian packages, repository name and distribution, e.g." >> $logFile
    echo "./repo_update.sh /srv/repo/packages myRepo focal" >> $logFile
fi

#Add new packages to repository
write_logdate
echo "Adding debian packages to aptly repository $repoName..." >>$logFile
aptly repo add $repoName $debianPackageLocation &>>$logFile
exit_on_error

#Create and publish new snapshot of repository
write_logdate
echo "Creating new snapshot $snapshotName from aptly repository $repoName..." >>$logFile
aptly snapshot create $snapshotName from repo $repoName &>>$logFile
exit_on_error

write_logdate
echo "Publishing new snapshot $snapshotName..." >>$logFile
aptly publish switch $distribution $endpointPrefix $snapshotName &>>$logFile
exit_on_error

exit $?
