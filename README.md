postgresql_auto_backup_s3
=========================

Configurable backup scripts to automate postgresql backups and push to s3 via stdin, plus rotation logic.

Contributors welcome!

Original code from https://wiki.postgresql.org/wiki/Automated_Backup_on_Linux.

Original S3 modification from https://github.com/vectorien/postgresql_auto_backup_s3

Adapted to work with standard awscli commands instead of s3cmd. Also, simplified to only backup the specified database, and only perform a custom (-Fc) dump. Assumes code is being run from a properly authenticated AWS CLI client.

Create a config file based on `pg_backup.config.template`, then run as follows:

```
sh pg_backup_rotated.sh -c backup.config
```

Can also be set up to run as a cron job.
