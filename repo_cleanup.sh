#!/bin/bash

#Set in repo_maintenance.incron & repo_cleanup.cron with repo_cleanup $@ ep-server
debianPackageLocation=$1 #Directory with debian packages
repoName=$2 #Name of aptly repository

#Get array of packages
aptlyPackages=$(aptly repo show -with-packages $repoName | sed '1,/Packages/d') #List packages in aptly repo
availableDebianPackages=$(ls $debianPackageLocation | grep .deb | sed 's/.deb$//') #List available debian packages in directory

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
    echo "No arguments supplied. Specify path to directory with debian packages, e.g." >> $logFile
    echo "./repo_update.sh /srv/repo/packages myRepo" >> $logFile
fi

echo "Cleaning up packages in aptly repository $repoName..." >>$logFile

for aptlyPackage in $aptlyPackages #Iterate over packages in aptly repo
do
 found=0 #Reset variable - package found in current run?
 for availableDebianPackage in $availableDebianPackages #Iterate over packages in directory for each package in aptly repo
  do
   if [ "$aptlyPackage" == "$availableDebianPackage" ] #Is aptly package name found in package directory? Then go to next
   then
    found=1
    write_logdate
    echo "$aptlyPackage available in $debianPackageLocation, skipped..." >>$logFile
   fi
  done
 if [ $found -eq 0 ] #If package in aptly repo not found in directory, remove it from repo
  then
   write_logdate
   echo "Removing package $aptlyPackage from aptly repository $repoName..." >>$logFile
   aptly repo remove $repoName $aptlyPackage &>>$logFile
   exit_on_error
 fi
done

echo "Done..." >>$logFile

exit $?
