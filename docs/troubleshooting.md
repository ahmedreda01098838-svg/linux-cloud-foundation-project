# Troubleshooting

This document records real troubleshooting cases from the Linux Cloud
Foundation project.

For every case, the format is:

- Problem
- Investigation
- Root cause
- Solution
- Verification

## 1. Client could not reach the server by IP

### Problem

`client01` temporarily could not communicate with `web01`.

### Investigation

Ran:

```bash
ping -c 3 192.168.122.160
```

The ping failed even though both VMs were running.

### Root cause

A stale or failed ARP neighbor entry existed on `client01` for the server IP.

### Solution

Removed the stale ARP entry:

```bash
sudo ip neigh del 192.168.122.160 dev enp1s0
```

### Verification

```bash
ping -c 3 192.168.122.160
```

Result:

```text
3 packets transmitted, 3 received, 0% packet loss
```

## 2. NGINX did not serve the custom project page

### Problem

The client received the default Fedora test page instead of the custom project
page.

### Investigation

Checked the NGINX configuration and confirmed that the custom page existed at
`/usr/share/nginx/html/index.html`.

### Root cause

The default NGINX page was still being served before the custom page was
deployed and verified.

### Solution

Replaced the default page with the custom project page.

### Verification

```bash
curl -I http://myserver.test
curl http://myserver.test
```

Result:

```text
HTTP/1.1 200 OK
Server: nginx/1.30.5
```

The custom project page was returned.

## 3. Apache failed to start because port 80 was in use

### Problem

Apache failed to start with:

```text
Job for httpd.service failed
```

### Investigation

Checked the service and journal:

```bash
sudo systemctl status httpd --no-pager
sudo journalctl -xeu httpd.service --no-pager
```

The log showed:

```text
(98)Address already in use: could not bind to address 0.0.0.0:80
```

### Root cause

NGINX was still listening on port 80, so Apache could not bind to the same
port.

### Solution

Stopped and disabled NGINX temporarily:

```bash
sudo systemctl disable --now nginx
```

Then started Apache.

### Verification

```bash
systemctl is-active httpd
curl -I http://localhost
```

Result:

```text
active
HTTP/1.1 200 OK
Server: Apache/2.4.68 (Fedora Linux)
```

## 4. Apache served an old default virtual host

### Problem

Apache returned an old test page from `/srv/linux-cloud-site` instead of the
project page.

### Investigation

Ran:

```bash
sudo httpd -S
```

The output showed an old virtual host:

```text
default server web01.lab.local
/etc/httpd/conf.d/linux-cloud-site.conf
DocumentRoot /srv/linux-cloud-site
```

### Root cause

Requests to `localhost` did not match `ServerName myserver.test`, so Apache
used the old default virtual host.

### Solution

Temporarily renamed the old configuration file:

```bash
sudo mv /etc/httpd/conf.d/linux-cloud-site.conf \
  /etc/httpd/conf.d/linux-cloud-site.conf.bak
```

Then restarted Apache.

### Verification

```bash
sudo httpd -S
curl -I http://localhost
```

Only the `myserver.test` virtual host remained, and Apache returned the project
page.

## 5. Health check automatically restarted NGINX during the Apache test

### Problem

NGINX started again while Apache was being tested, causing another port 80
conflict.

### Investigation

Checked the health-check log:

```bash
sudo tail -n 10 /var/log/linux-cloud-foundation/health-check.log
```

The log showed:

```text
WARNING: NGINX health check failed
INFO: attempting controlled NGINX restart
OK: NGINX recovered after restart
```

### Root cause

`project-healthcheck.timer` detected that NGINX was stopped and restarted it
automatically.

### Solution

Temporarily stopped the health-check timer during the Apache comparison:

```bash
sudo systemctl stop project-healthcheck.timer
```

### Verification

NGINX remained inactive while Apache was tested. After the comparison, NGINX
and the timer were started again.

## 6. HTTPS request to localhost failed certificate verification

### Problem

Running:

```bash
curl -fsS [https://localhost/health](https://localhost/health)
```

Failed with:

```text
SSL: certificate subject name 'myserver.test' does not match target hostname 'localhost'
```

### Root cause

The self-signed certificate was issued for `myserver.test`, not `localhost`.

### Solution

Used either `-k` for the local test:

```bash
curl -kfsS [https://localhost/health](https://localhost/health)
```

Or used the correct hostname from `client01`:

```bash
curl -kfsS [https://myserver.test/health](https://myserver.test/health)
```

### Verification

Both commands returned:

```text
OK
```

## 7. Deleted web page was restored from backup

### Problem

A harmless test page, `restore-test.html`, was deliberately deleted to test
backup restoration.

### Investigation

Confirmed the page was gone:

```bash
curl -kI [https://localhost/restore-test.html](https://localhost/restore-test.html)
```

Result:

```text
HTTP/2 404
```

Confirmed that the backup archive contained the file:

```bash
sudo tar -tzf /srv/backups/linux-cloud-backup-20261009-231511.tar.gz | grep restore-test.html
```

### Root cause

The file had been intentionally deleted; this was the expected failure state.

### Solution

Extracted the file from the backup archive to a temporary directory, copied it
back to `/usr/share/nginx/html`, restored ownership and permissions, and
restored the SELinux context.

### Verification

```bash
curl -kI [https://localhost/restore-test.html](https://localhost/restore-test.html)
curl -kfsS [https://localhost/restore-test.html](https://localhost/restore-test.html)
```

Result:

```text
HTTP/2 200
```

The restored page returned its original content.
