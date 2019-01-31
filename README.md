postgresql_auto_backup_s3
=========================

Configurable backup scripts to automate postgresql backups and push to s3 via stdin, plus rotation logic.

Contributors welcome!

Original code from https://wiki.postgresql.org/wiki/Automated_Backup_on_Linux.

Original S3 modification from https://github.com/vectorien/postgresql_auto_backup_s3

Adapted to work with standard awscli commands instead of s3cmd. Also, simplified to only backup the specified database, and only perform a custom (-Fc) dump. Assumes code is being run from a properly authenticated AWS CLI client.

Set a single bucket for your backups. Subfolders are created based on the supplied database name, and files are also named with the database name and dates. Backups end up looking like this:

```
db_name_2018-12-01_monthly.dump.gz
db_name_2018-12-03_weekly.dump.gz
db_name_2018-12-10_weekly.dump.gz
db_name_2018-12-17_weekly.dump.gz
db_name_2018-12-24_weekly.dump.gz
db_name_2019-01-01_weekly.dump.gz
db_name_2019-01-06_daily.dump.gz
db_name_2019-01-07_daily.dump.gz
db_name_2019-01-08_daily.dump.gz
db_name_2019-01-09_daily.dump.gz
db_name_2019-01-10_daily.dump.gz
db_name_2019-01-11_daily.dump.gz
```

The number of daily and weekly backups to keep is set via config. Currently, all monthly backups are kept.

Create a config file based on `pg_backup.config.template`, then run as follows:

```
sh pg_backup_rotated.sh -c backup.config
```

Can also be set up to run as a cron job.
