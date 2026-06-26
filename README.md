# MySQL Backup

Small Bash utility to dump a configured MySQL database, copy the compressed dump to a remote VM, and keep only the last 3 days of local backups.

## Setup

```bash
cp backup.conf.example backup.conf
chmod 600 backup.conf
chmod +x mysql-backup.sh
```

Edit `backup.conf` with the MySQL connection, local backup directory, and remote VM destination.

The remote backup directory must already exist and the configured SSH user must be able to write to it.

## Run

```bash
./mysql-backup.sh
```

Or pass a custom config file:

```bash
./mysql-backup.sh /path/to/backup.conf
```

Backups are written as:

```text
<DB_NAME>_<YYYYmmdd_HHMMSS>.sql.gz
```

## Cron

Example daily run at 2:00 AM:

```cron
0 2 * * * /home/raviks/Projects/mysql-backup/mysql-backup.sh /home/raviks/Projects/mysql-backup/backup.conf >> /var/log/mysql-backup.log 2>&1
```

## Local Retention

After a successful remote copy, the script deletes local backup files matching the configured database name that are older than 3 days.
