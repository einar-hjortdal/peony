# [Percona Server for MySQL](https://www.percona.com/software/mysql-database/percona-server)

Instead of running MySQL provided by EuroLinux, I recommend to use Percona Server for MySQL. Percona 
Server for MySQL is available as a container image from Percona itself.

The container is created by the root user to protect the container and files from unauthorized access. 
All the commands below are run as root user.

## Setup

```bash
# Get the Percona Server container image
podman pull docker.io/percona/percona-server:latest

# Prepare directories and files.
# By default the file /etc/my.cnf includes the /etc/my.cnf.d directory
cd ~
mkdir -p percona/data
touch percona/my.cnf
chown -R 2000 percona
chcon -Rt container_file_t percona

# Create a temporary container instance
podman run \
  --detach \
  --env="MYSQL_RANDOM_ROOT_PASSWORD=yes" \
  --name=percona \
  --tz=local \
  --mount=type=bind,src=/root/percona/data,dst=/var/lib/mysql \
  --publish=29300:3306 \
  --user=2000 \
  --rm \
  percona/percona-server

# Check the randomly generated password in the logs.
# these notes assume that the generated password is Yk3B0L0c(YG^0D@HoqOM0qJuL%Il
podman logs percona 2>&1 | grep "GENERATED ROOT PASSWORD"

# Access the container's shell
podman exec -it percona /bin/bash

# Access Percona Server
mysql -uroot -p
# Enter the password

# Create a database and user.
# The host must be set to % to allow connections from outside of the container
CREATE DATABASE peony_db;
CREATE USER 'peony_user'@'%' IDENTIFIED BY 'some_password';
GRANT ALL ON peony_db.* TO 'peony_user'@'%' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EXIT;

# Exit the container's shell
exit

# Stop the temporary container instance
podman stop percona

# Add the generated password to the new configuration file
vim percona/my.cnf
```

This configuration file is required:
- The `[mysqld]` block adds `ANSI` to the default Percona Server mode, to make the server behave more 
closely to SQL standard specifications.
- The `[mysqlpump]` block helps with automating logical backups

```conf
[mysqld]
sql-mode="ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION,ANSI"

[mysqlpump]
user=root
password="Yk3B0L0c(YG^0D@HoqOM0qJuL%Il"
```

```bash
# Run the final container instance
podman run \
  --detach \
  --name=percona \
  --publish=29300:3306 \
  --label="io.containers.autoupdate=registry" \
  --tz=local \
  --mount=type=bind,src=/root/percona/my.cnf,dst=/etc/my.cnf.d/my.cnf,readonly=true \
  --mount=type=bind,src=/root/percona/data,dst=/var/lib/mysql \
  --user=2000 \
  docker.io/percona/percona-server:latest

# Configure the container as a service
# Generate systemd service file
podman generate systemd --new --name --files percona

# Copy the service file to the correct location
cp container-percona.service /etc/systemd/system/

# Allow systemd to see the files
restorecon -R /etc/systemd/system/

# Reload systemd, enable and start the service
systemctl daemon-reload
systemctl enable --now container-percona
```

<!-- TODO
## Backups

It is safest to perform both physical and logical backups. Physical backups can be performed by archiving 
the `/root/percona` directory.

```bash
# First stop the container
systemctl stop container-percona

# Perform the backup
tar --preserve-permissions --gzip --create --file=percona_backup.tar.gz -C / /root/percona

# Then restart the container
systemctl start container-percona
```

Logical backups can be performed with mysqlpump.

```bash
podman exec percona bash -c \
  'mysqlpump \
  --include-databases=peonyDb \
  --include-users=peonyUser \
  --single-transaction' \
  > /root/bkp.sql
```
-->
