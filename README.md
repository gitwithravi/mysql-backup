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

## MySQL Backup User

Create a dedicated MySQL user instead of using `root` or an application user. Replace `my_database`, `backup_user`, and `strong_password_here` with your values.

```sql
CREATE USER 'backup_user'@'localhost' IDENTIFIED BY 'strong_password_here';
GRANT SELECT, SHOW VIEW, TRIGGER, EVENT, LOCK TABLES ON `my_database`.* TO 'backup_user'@'localhost';
FLUSH PRIVILEGES;
```

The script uses `mysqldump --no-tablespaces`, so the backup user does not need the global `PROCESS` privilege on MySQL 8.

If the script connects from another host, replace `localhost` with that host or IP address:

```sql
CREATE USER 'backup_user'@'backup_server_ip' IDENTIFIED BY 'strong_password_here';
GRANT SELECT, SHOW VIEW, TRIGGER, EVENT, LOCK TABLES ON `my_database`.* TO 'backup_user'@'backup_server_ip';
FLUSH PRIVILEGES;
```

Use the same username and password in `backup.conf`:

```bash
DB_NAME="my_database"
DB_USER="backup_user"
DB_PASSWORD="strong_password_here"
```

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
