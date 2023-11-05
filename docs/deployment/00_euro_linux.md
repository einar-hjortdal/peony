# Euro Linux 9

## Podman

Podman, the daemonless container engine for OCI containers, is shipped on Euro Linux official repositories. 
There is no point in using Docker, as Podman is just better in many ways. Read more about Podman [here](https://podman.io/)

```bash
# Install Podman
sudo dnf install container-tools -y
```

### Auto-update container images

```bash
systemctl enable --now podman-auto-update.timer
systemctl edit podman-auto-update.timer
```

The override file will contain the following lines

```conf
[Timer]
OnCalendar=Mon *-*-* 03:00:00
Persistent=true
```

peony will be unusuable on Mondays at 3am for a brief period of time, if an update has to be applied. 
Before any update is applied, it is best to get a logical backup.

A logical backup can be performed with the database online, but it is good practice to take down the 
API entirely a few minutes before the updates are applied.
