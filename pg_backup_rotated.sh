#!/bin/bash

###########################
####### LOAD CONFIG #######
###########################

while [ $# -gt 0 ]; do
        case $1 in
                -c)
                        CONFIG_FILE_PATH="$2"
                        shift 2
                        ;;
                *)
                        ${ECHO} "Unknown Option \"$1\"" 1>&2
                        exit 2
                        ;;
        esac
done

if [ -z $CONFIG_FILE_PATH ] ; then
        SCRIPTPATH=$(cd ${0%/*} && pwd -P)
        CONFIG_FILE_PATH="${SCRIPTPATH}/pg_backup.config"
fi

if [ ! -r ${CONFIG_FILE_PATH} ] ; then
        echo "Could not load config file from ${CONFIG_FILE_PATH}" 1>&2
        exit 1
fi

source "${CONFIG_FILE_PATH}"

###########################
#### PRE-BACKUP CHECKS ####
###########################

# Make sure we're running as the required backup user
if [ "$BACKUP_USER" != "" -a "$(id -un)" != "$BACKUP_USER" ] ; then
	echo "This script must be run as $BACKUP_USER. Exiting." 1>&2
	exit 1
fi

###########################
### INITIALISE DEFAULTS ###
###########################

if [ ! $HOSTNAME ]; then
	HOSTNAME="localhost"
    echo "No host specified, using localhost"
fi;

if [ ! $USERNAME ]; then
	USERNAME="postgres"
    echo "No user specified, using postgres"
fi;

if [ ! $DATABASE ]; then
    DATABASE="postgres"
    echo "No database specified, backing up postgres"
fi;

if [ ! $BACKUP_PATH ]; then
    BACKUP_PATH="$DATABASE"
    echo "No backup path specified, using database name as path"
fi;


TODAY=`date +\%Y-\%m-\%d`
# TODAY="2019-01-12"
echo "Today is: ${TODAY}"

###########################
#### START THE BACKUP #####
###########################

# NOTE: This has been refactored from the original to reduce the number of pg_dump calls

echo "Performing full backup"
echo "--------------------------------------------"
echo "Custom backup of $DATABASE"
	if ! pg_dump -Fc -w -h "$HOSTNAME" -U "$USERNAME" "$DATABASE" | gzip --stdout | aws s3 cp - s3://${BACKUP_BUCKET}/${BACKUP_PATH}/${DATABASE}_${TODAY}_daily.dump.gz.in_progress; then
        	echo "[!!ERROR!!] Failed to produce custom backup database schema of $DATABASE" 1>&2
	else
        	aws s3 mv s3://${BACKUP_BUCKET}/${BACKUP_PATH}/${DATABASE}_${TODAY}_daily.dump.gz.in_progress s3://${BACKUP_BUCKET}/${BACKUP_PATH}/${DATABASE}_${TODAY}_daily.dump.gz
	fi

echo "Backup complete!"

# MANAGE BACKUPS

echo "Managing prior backups"
echo "--------------------------------------------"

DAILY_BACKUPS=$(aws s3api list-objects-v2 --bucket $BACKUP_BUCKET --prefix $BACKUP_PATH --query 'sort_by(Contents, &Key)[?contains(Key, `daily`)].Key' --output text)
DAILY_BACKUPS=(${DAILY_BACKUPS//'\n'/})
echo "Total daily backups: ${#DAILY_BACKUPS[@]}"
# echo "Daily backups: ${DAILY_BACKUPS}"
# WEEKLY_BACKUPS=`aws s3api list-objects-v2 --bucket $BACKUP_BUCKET --prefix $DATABASE --query 'sort_by(Contents, &Key)[?contains(Key, `weekly`)].{Key: Key}' --output text`
# MONTHLY_BACKUPS=`aws s3api list-objects-v2 --bucket $BACKUP_BUCKET --prefix $DATABASE --query 'sort_by(Contents, &Key)[?contains(Key, `monthly`)].{Key: Key}' --output text`

if (( ${#DAILY_BACKUPS[@]} == ${DAYS_TO_KEEP} + 1 ));
then

    DAY_OF_WEEK=`date +%u` #1-7 (Monday-Sunday)
    echo "Day of week: ${DAY_OF_WEEK}"

    if (( $DAY_OF_WEEK == $DAY_OF_WEEK_TO_KEEP ));
    then
        echo "Today is the weekly backup day, renaming expired daily backup to weekly backup"
        # Take the 8th daily backup and rename it to weekly
        NEW_WEEKLY=${DAILY_BACKUPS[0]}
        aws s3 mv s3://${BACKUP_BUCKET}/${DAILY_BACKUPS[0]} s3://${BACKUP_BUCKET}/${NEW_WEEKLY/daily/weekly}
        # Now, lets count the weekly backups
        WEEKLY_BACKUPS=$(aws s3api list-objects-v2 --bucket $BACKUP_BUCKET --prefix $DATABASE --query 'sort_by(Contents, &Key)[?contains(Key, `weekly`)].Key' --output text)
        WEEKLY_BACKUPS=(${WEEKLY_BACKUPS//'\n'/})
        echo "Total weekly backups: ${#WEEKLY_BACKUPS[@]}"
        if (( ${#WEEKLY_BACKUPS[@]} > $WEEKS_TO_KEEP ));
        then
            echo "Removing expired weekly backup"
            # remove the oldest weekly backup
            aws s3 rm s3://${BACKUP_BUCKET}/${WEEKLY_BACKUPS[0]}
        fi
    else
        echo "Today is not the weekly backup day, deleting ${DAILY_BACKUPS[0]}"
        aws s3 rm s3://${BACKUP_BUCKET}/${DAILY_BACKUPS[0]}
    fi

    DAY_OF_MONTH=`date +%d`
    echo "Day of month: ${DAY_OF_MONTH}"

    if (( $DAY_OF_MONTH == 1 ));
    then
        echo "Today is the first of the month, creating a monthly backup"
        # if today is the first of the month, we also make a copy of today's backup and tag it as monthly
        NEW_MONTHLY=${DAILY_BACKUPS[-1]}
        aws s3 cp s3://${BACKUP_BUCKET}/${NEW_MONTHLY} s3://${BACKUP_BUCKET}/${NEW_MONTHLY/daily/monthly}
        # Eventually, we might want to stop keeping monthly backups
    fi
    exit 0;
fi
