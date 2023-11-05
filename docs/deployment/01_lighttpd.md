# Lighttpd

The web server lighttpd should be installed on Euro Linux 9 with an RPM package.

lighttpd packages for Euro Linux 9 are available on `rpm.TODO.com`, add the respository with 
`sudo vi /etc/yum.repos.d/todo.repo`

```conf
[todo]
name=todo
baseurl=https://rpm.TODO.com
enabled=1
gpgcheck=1
priority=80
gpgkey=https://rpm.TODO.com/rpm-gpg/RPM-GPG-KEY-todo
```

Install and start lighttpd

```bash
# Install lighttpd
sudo dnf install lighttpd -y

# Start and enable lighttpd
sudo systemctl enable --now lighttpd

# Check the status of lighttpd
sudo systemctl status lighttpd

# As shown by the status, lighttpd requires this SELinux boolean
sudo setsebool -P httpd_setrlimit on
```

lighttpd configuration files are in `/etc/lighttpd`, these configuration files contain explanations 
related to the configurations they contain, I recommend you read them. Sample configuration files for 
a peony deployment are available in the `lighttpd_config` directory.

```bash
# Create files and directories according to virtual hosts configuration
# The following commands match the supplied sample configurtion files
#
# First create the log directories and files with the appropriate permissions
#
sudo mkdir /var/log/lighttpd/coachonko.com \
  /var/log/lighttpd/admin.coachonko.com \
  /var/log/lighttpd/api.coachonko.com \
  /var/log/lighttpd/garage.coachonko.com
sudo touch /var/log/lighttpd/coachonko.com/access.log /var/log/lighttpd/coachonko.com/error.log \
  /var/log/lighttpd/admin.coachonko.com/access.log /var/log/lighttpd/admin.coachonko.com/error.log \
  /var/log/lighttpd/api.coachonko.com/access.log /var/log/lighttpd/api.coachonko.com/error.log \
  /var/log/lighttpd/garage.coachonko.com/access.log /var/log/lighttpd/garage.coachonko.com/error.log
sudo chown -R lighttpd:lighttpd /var/log/lighttpd/coachonko.com \
  /var/log/lighttpd/admin.coachonko.com \
  /var/log/lighttpd/api.coachonko.com \
  /var/log/lighttpd/garage.coachonko.com

# Then create the directories for TLS certificates and issue self-signed certificates
sudo mkdir -p /etc/pki/www/{private,certs}
sudo openssl req -x509 -nodes -days 90 -addext "subjectAltName = DNS:gb00.coachonko.com" -newkey rsa:2048 -keyout /etc/pki/www/private/gb00.coachonko.com.key -out /etc/pki/www/certs/gb00.coachonko.com.pem -subj "/C=GB/ST=London/L=London/O=Global Security/OU=IT Department/CN=gb00.coachonko.com"
sudo openssl req -x509 -nodes -days 90 -addext "subjectAltName = DNS:coachonko.com" -newkey rsa:2048 -keyout /etc/pki/www/private/coachonko.com.key -out /etc/pki/www/certs/coachonko.com.pem -subj "/C=GB/ST=London/L=London/O=Global Security/OU=IT Department/CN=coachonko.com"
sudo openssl req -x509 -nodes -days 90 -addext "subjectAltName = DNS:api.coachonko.com" -newkey rsa:2048 -keyout /etc/pki/www/private/api.coachonko.com.key -out /etc/pki/www/certs/api.coachonko.com.pem -subj "/C=GB/ST=London/L=London/O=Global Security/OU=IT Department/CN=api.coachonko.com"
sudo openssl req -x509 -nodes -days 90 -addext "subjectAltName = DNS:admin.coachonko.com" -newkey rsa:2048 -keyout /etc/pki/www/private/admin.coachonko.com.key -out /etc/pki/www/certs/admin.coachonko.com.pem -subj "/C=GB/ST=London/L=London/O=Global Security/OU=IT Department/CN=admin.coachonko.com"
sudo openssl req -x509 -nodes -days 90 -addext "subjectAltName = DNS:garage.coachonko.com" -newkey rsa:2048 -keyout /etc/pki/www/private/garage.coachonko.com.key -out /etc/pki/www/certs/garage.coachonko.com.pem -subj "/C=GB/ST=London/L=London/O=Global Security/OU=IT Department/CN=garage.coachonko.com"

# Now it is possible to reload lighttpd to use the new configurations
sudo systemctl reload lighttpd
```
