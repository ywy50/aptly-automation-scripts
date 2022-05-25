#!/bin/bash

deleteDate=$1 # Example: "-1 day" - Set in repo_cleanup.cron with /usr/local/bin/snapshot_cleanup "-1 day"

#List available snapshots and 
snapshots=$(aptly snapshot list | sed '1d' | sed '$d' | cut -d '[' -f 2 | cut -d ']' -f 1)
oldDate=$(date --date="$deleteDate" +%Y-%m-%d_%H%M%S)

#Write logs
logFile=/var/log/aptly/snapshot_cleanup.log
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
    echo "No arguments supplied. Specify timing for snapshots to be considered old! Examples:" >> $logFile
    echo " '-1 day', '-20 minutes', '-5 hours' " >> $logFile
    echo " /usr/local/bin/snapshot_cleanup '-1 day' " >> $logFile
fi

write_logdate
echo "Removing old aptly snapshots..." >>$logFile

for snapshot in $snapshots
do
        snapshotDate=$snapshot
        if [ $snapshotDate \> $oldDate ]
        then
                write_logdate
                echo "Snapshot $snapshot newer than $deleteDate, skipped..." >> $logFile

        elif [ $snapshotDate \< $oldDate ]
        then
                write_logdate
                echo "Deleting snapshot $snapshot older than $deleteDate, $oldDate..." >> $logFile
                aptly snapshot drop $snapshot &>>$logFile
                exit_on_error 

        fi
done

write_logdate
aptly db cleanup &>>$logFile
exit_on_error

exit $?
