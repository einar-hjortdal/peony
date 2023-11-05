<!-- TODO
localhost/127.0.0.1 should be replaced with host.containers.internal 

Build the container image with `podman build -t peony -f Containerfile`

podman run \
  --detach \
  --name=peony \
  --tz=local \
  --publish=29000:29000 \
  --rm \
  localhost/peony
  -->