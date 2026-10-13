# Implementation Log

## Project baseline

This project uses two Fedora Server VMs on the Fedora host.

| VM | Hostname | IP address | Role |
|---|---|---|---|
| web01 | web01.lab.local | 192.168.122.160/24 | NFS server |
| client01 | client01.lab.local | 192.168.122.221/24 | NFS client |

Both VMs use DHCP on the libvirt network.

## web01 baseline

- OS: Fedora Linux 44 Server Edition
- Kernel: 7.2.8-200.fc44.x86_64
- Interface: enp1s0
- IP address: 192.168.122.160/24
- Gateway: 192.168.122.1
- DNS: 192.168.122.1
- SELinux mode: Enforcing
- Root filesystem: XFS on LVM volume fedora-root
- /srv filesystem: XFS on LVM volume fedora-webdata
- NFS export: /srv/nfs-share to 192.168.122.221

## client01 baseline

- OS: Fedora Linux 44 Server Edition
- Kernel: 7.2.8-200.fc44.x86_64
- Interface: enp1s0
- IP address: 192.168.122.221/24
- Gateway: 192.168.122.1
- DNS: 192.168.122.1
- SELinux mode: Enforcing
- Root filesystem: XFS on LVM volume fedora-root
- NFS mount: /mnt/nfs-share from web01:/srv/nfs-share

## Phase 2: NFS lab result

- web01 exports /srv/nfs-share to client01 (192.168.122.221).
- client01 mounts it at /mnt/nfs-share.
- NFSv3 over TCP is used for this lab.
- rpcbind, mountd, and nfs services are verified with rpcinfo.
- firewalld allows ports 111/tcp, 111/udp, 20048/tcp, 20048/udp.
- File README.txt was successfully read through the NFS mount.

## Phase 3: Local hostname resolution

- Added this client-only entry to `/etc/hosts` on client01:

  ```text
  192.168.122.160 web01.lab.local web01 myserver.test
  ```

- Verified name resolution:

  ```text
  getent hosts myserver.test
  ```

  Result: `192.168.122.160 web01.lab.local web01 myserver.test`

- Verified connectivity:

  ```text
  ping -c 3 myserver.test
  ```

  Result: 3 packets transmitted, 3 received, 0% packet loss.

- Troubleshooting note: client01 temporarily had a failed ARP neighbor entry for web01. The issue was resolved by clearing the entry:

  ```bash
  sudo ip neigh del 192.168.122.160 dev enp1s0
  ```

- Verified that the ARP entry was refreshed successfully:

  ```text
  ping -c 3 192.168.122.160
  ```

  Result: 3 packets transmitted, 3 received, 0% packet loss.

## Phase 4: Users and secure SSH

- Created administrative user `webadmin` on web01.
- Added `webadmin` to the `wheel` group.
- Generated an Ed25519 SSH key pair on client01.
- Installed the public key for `webadmin` on web01.
- Verified passwordless SSH key authentication from client01 to web01.
- Changed the SSH listener port from 22 to 2028.
- Allowed TCP port 2028 in firewalld.
- Allowed SELinux to bind sshd to TCP port 2028 using:

  ```bash
  sudo semanage port -a -t ssh_port_t -p tcp 2028
  ```

- Disabled direct root SSH login:

  ```text
  PermitRootLogin no
  ```

- Disabled SSH password authentication:

  ```text
  PasswordAuthentication no
  ```

- Enabled public key authentication:

  ```text
  PubkeyAuthentication yes
  ```

- Validated the SSH configuration with:

  ```bash
  sudo sshd -t
  ```

- Restarted and verified sshd:

  ```bash
  sudo systemctl restart sshd
  sudo systemctl status sshd --no-pager
  ```

- Verified that sshd listens on port 2028:

  ```bash
  sudo ss -ltnp | grep sshd
  ```

- Verified secure SSH access from client01:

  ```bash
  ssh -p 2028 webadmin@192.168.122.160 'whoami; hostname'
  ```

  Result:

  ```text
  webadmin
  web01.lab.local
  ```

## Phase 5: NFS access control and permissions

- Created the `nfsusers` group on web01 and client01.
- Created the `nfsuser` user on web01 and added it to `nfsusers`.
- Added `webadmin` and `aamd` to the `nfsusers` group.
- Set `/srv/nfs-share` ownership to `root:nfsusers`.
- Set `/srv/nfs-share` permissions to `2770` so new files inherit the `nfsusers` group.
- Corrected the SELinux context from `httpd_sys_content_t` to `public_content_rw_t`:

  ```bash
  sudo semanage fcontext -a -t public_content_rw_t '/srv/nfs-share(/.*)?'
  sudo restorecon -Rv /srv/nfs-share
  ```

- Enabled the SELinux boolean required for NFS writes:

  ```bash
  sudo setsebool -P nfsd_anon_write on
  ```

- Changed the NFS export from read-only to read-write:

  ```text
  /srv/nfs-share 192.168.122.221(rw,sync,no_subtree_check,root_squash)
  ```

- Applied the export configuration:

  ```bash
  sudo exportfs -ra
  ```

- Replaced the NFSv3 mount with an NFSv4.2 mount to avoid NFSv3 lock-manager port issues:

  ```bash
  sudo mount -t nfs -o vers=4.2,soft,intr 192.168.122.160:/srv/nfs-share /mnt/nfs-share
  ```

- Added a persistent mount entry to `/etc/fstab`:

  ```text
  192.168.122.160:/srv/nfs-share  /mnt/nfs-share  nfs  vers=4.2,soft,intr  0  0
  ```

- Reloaded systemd after modifying `/etc/fstab`:

  ```bash
  sudo systemctl daemon-reload
  ```

- Verified successful NFS write access from client01:

  ```bash
  touch /mnt/nfs-share/client-write-test.txt
  echo "NFSv4.2 write test from client01" > /mnt/nfs-share/client-write-test.txt
  cat /mnt/nfs-share/client-write-test.txt
  ```

  Result:

  ```text
  NFSv4.2 write test from client01
  ```

## Phase 6: Web server deployment

- Installed NGINX on web01:

  ```bash
  sudo dnf install -y nginx
  ```

- Found that Apache HTTP Server was already using port 80.
- Disabled and stopped Apache to free port 80:

  ```bash
  sudo systemctl disable --now httpd
  ```

- Enabled and started NGINX:

  ```bash
  sudo systemctl enable --now nginx
  ```

- Verified that NGINX is running and listening on port 80:

  ```bash
  sudo systemctl status nginx --no-pager
  sudo ss -ltnp | grep nginx
  ```

- Verified that the HTTP service is allowed in firewalld:

  ```bash
  sudo firewall-cmd --permanent --add-service=http
  sudo firewall-cmd --reload
  ```

- Created a custom project page at `/usr/share/nginx/html/index.html`.
- Verified local access on web01:

  ```bash
  curl -I http://localhost
  ```

  Result: `HTTP/1.1 200 OK`

- Verified access from client01 using the local hostname:

  ```bash
  curl -I http://myserver.test
  curl http://myserver.test
  ```

  Result:

  ```text
  HTTP/1.1 200 OK
  Server: nginx/1.30.5
  ```

- Confirmed that client01 receives the custom project page instead of the default Fedora test page.

## HTTPS stretch goal: self-signed TLS

- Created a self-signed TLS certificate for `myserver.test`:

  ```bash
  sudo openssl req -x509 -nodes -days 365 \
    -newkey rsa:2048 \
    -keyout /etc/nginx/ssl/myserver.test.key \
    -out /etc/nginx/ssl/myserver.test.crt \
    -subj "/CN=myserver.test/O=Linux Cloud Foundation/C=EG"
  ```

- Certificate details:

  ```text
  subject=CN=myserver.test, O=Linux Cloud Foundation, C=EG
  notBefore=Oct  9 19:18:56 2026 GMT
  notAfter=Oct  9 19:18:56 2027 GMT
  ```

- Set private key permissions to `600` and certificate permissions to `644`.
- Created `/etc/nginx/conf.d/myserver.test.conf`.
- Configured NGINX to redirect HTTP requests on port 80 to HTTPS.
- Configured NGINX to serve HTTPS on port 443 using TLSv1.2 and TLSv1.3.
- Enabled HTTP/2.
- Validated the NGINX configuration:

  ```bash
  sudo nginx -t
  ```

  Result:

  ```text
  nginx: configuration file /etc/nginx/nginx.conf test is successful
  ```

- Reloaded NGINX:

  ```bash
  sudo systemctl reload nginx
  ```

- Enabled the HTTPS service in firewalld:

  ```bash
  sudo firewall-cmd --permanent --add-service=https
  sudo firewall-cmd --reload
  ```

- Verified HTTPS access from client01:

  ```bash
  curl -kI https://myserver.test
  curl -k https://myserver.test
  ```

  Result:

  ```text
  HTTP/2 200
  server: nginx/1.30.5
  ```

  The custom project page was returned successfully.

- Verified automatic HTTP-to-HTTPS redirection:

  ```bash
  curl -I http://myserver.test
  ```

  Result:

  ```text
  HTTP/1.1 301 Moved Permanently
  Location: https://myserver.test/
  ```

- HTTPS stretch goal completed successfully.

## Phase 7: Storage and backup design

- Reviewed storage on web01:

  ```text
  /    15G total, 13G available, 18% used
  /srv  8G total, 7.8G available, 3% used
  LVM free space: 4.51G
  ```

- `/srv` is a separate XFS filesystem on the `fedora-webdata` LVM logical volume.
- Selected `/srv/backups` as the local backup staging directory.
- Created `/srv/backups` with ownership `root:webadmin` and permissions `750`.
- Set a persistent SELinux context for the backup directory:

  ```bash
  sudo semanage fcontext -a -t var_t '/srv/backups(/.*)?'
  sudo restorecon -Rv /srv/backups
  ```

- Verified the final context:

  ```text
  unconfined_u:object_r:var_t:s0 /srv/backups
  ```

- Created `/usr/local/sbin/disk-check.sh`.
- The script checks `/` and `/srv` usage.
- It logs an OK entry when usage is below 80%.
- It logs a WARNING entry and returns exit code 1 when usage reaches 80%.
- It logs an ERROR entry and returns exit code 2 if a monitored mountpoint is unavailable.
- Created the log directory and file:

  ```text
  /var/log/linux-cloud-foundation/disk-check.log
  ```

- Tested the script successfully:

  ```text
  OK: / usage is 18% (available: 13G)
  OK: /srv usage is 3% (available: 7.8G)
  Exit code: 0
  ```
