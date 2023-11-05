# [KeyDB](https://github.com/snapchat/keydb)

Unlike Redis, KeyDB is multithreaded by default. This means that when KeyDB is deployed to a server 
running a CPU with many threads, it is not necessary to run 6 or more KeyDB shards and joining these 
shards together in a cluster.

All the commands below are run as root user.

```bash
# Prepare directories
cd ~
mkdir -p keydb/data
touch keydb/keydb.conf
chcon -Rt container_file_t keydb

# Create a temporary container instance
podman run \
  --detach \
  --name=keydb \
  --tz=local \
  --publish=29400:6379 \
  --rm \
  docker.io/eqalpha/keydb:latest

# Copy the default configuration file into the new configuration file
podman exec keydb bash -c "cat /etc/keydb/keydb.conf" >> keydb/keydb.conf

# Generate a pseudorandom password and add it to keydb.conf with the requirepass directive
podman exec -it keydb /usr/local/bin/keydb-cli
ACL GENPASS 256
EXIT

# Stop the temporary container instance
podman stop keydb

# Run the final container instance
podman run \
  --detach \
  --name=keydb \
  --publish=29400:6379 \
  --label="io.containers.autoupdate=registry" \
  --tz=local \
  --mount=type=bind,src=/root/keydb/keydb.conf,dst=/etc/keydb/keydb.conf \
  --mount=type=bind,src=/root/keydb/data,dst=/data \
  --rm \
  docker.io/eqalpha/keydb:latest

# Configure the pod as a service
podman generate systemd --new --name --files keydb

# Copy the service files to the correct location
cp container-keydb.service /etc/systemd/system/

# Reload systemd, enable and start the service
systemctl daemon-reload
systemctl enable --now container-keydb
```
