postgresql_auto_backup_s3
=========================

Configurable backup scripts to automate postgresql backups and push to s3 via stdin, plus rotation logic.

Contributors welcome!

Original code from https://wiki.postgresql.org/wiki/Automated_Backup_on_Linux.

Will be adapted to work with s3cmd stdin pushing, therefore needs s3cmd >= s3cmd 1.5.0-alpha1 , also see http://s3tools.org/news

Further reads:

http://engineroom.trackmaven.com/blog/3-2-1-backup-of-postgres-on-aws-to-s3-and-offsite-server/
http://zaiste.net/2015/01/backup_postgresql_to_amazon_s3/
https://github.com/wal-e/wal-e
