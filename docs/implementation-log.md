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
