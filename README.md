# Secure Linux Web Server Lab

## Overview

This project demonstrates practical Linux system administration and cloud
foundation skills using a small, isolated client/server lab built with two
Fedora Server virtual machines on a Fedora host.

The project covers secure SSH access, NFS storage, web server deployment,
HTTPS, firewalld, SELinux, backup and restore, monitoring, automation, and
Apache versus Nginx comparison.

## Architecture

```text
Fedora Host
├── VS Code, Git, and GitHub
├── libvirt virtual network
│
├── web01.lab.local (192.168.122.160)
│   ├── NGINX web server
│   ├── HTTPS with self-signed TLS
│   ├── NFS server
│   ├── firewalld and SELinux Enforcing
│   ├── Bash scripts and systemd timers
│   └── local backup staging at /srv/backups
│
└── client01.lab.local (192.168.122.221)
    ├── curl-based client testing
    ├── SSH key access to web01
    ├── NFS client
    └── off-server backup destination
```

## Technologies

- Fedora Server 44
- libvirt/KVM virtual machines
- Bash
- systemd and systemd timers
- NGINX
- Apache HTTP Server
- NFSv4.2
- OpenSSH
- firewalld
- SELinux
- OpenSSL
- tar and SHA-256
- Git and GitHub

## Features

- Isolated two-VM client/server lab.
- SSH key-only authentication on a non-default port.
- Disabled direct root SSH login and password authentication.
- NFSv4.2 share with group-based write access.
- NGINX serving a custom static project site.
- HTTPS using a self-signed TLS certificate.
- Automatic HTTP-to-HTTPS redirection.
- HTTP/2 support.
- Disk usage monitoring with an 80% warning threshold.
- Verified backup archives with SHA-256 checksums.
- Off-server backup copy to client01 over SSH.
- Verified restore test with HTTP validation.
- Automated NGINX health checks.
- Controlled service recovery with a single restart attempt.
- Apache and Nginx comparison using the same static content.

## Security controls

- SSH password authentication is disabled.
- Direct root SSH login is disabled.
- SSH uses Ed25519 key authentication.
- SSH listens on TCP port 2028.
- SELinux remains in Enforcing mode.
- firewalld exposes only required services.
- TLS private keys are excluded from backup archives.
- Backup archives and checksums use restrictive permissions.
- No passwords, private keys, or secrets are stored in this repository.

## Setup summary

1. Create two Fedora Server VMs on an isolated libvirt network.
2. Configure local hostname resolution with `/etc/hosts`.
3. Create an administrative user and configure SSH key authentication.
4. Harden SSH and change its listening port.
5. Configure NFS storage and SELinux contexts.
6. Deploy NGINX and the custom project site.
7. Configure HTTPS with a self-signed certificate.
8. Create disk monitoring, backup, and health-check scripts.
9. Schedule automation with systemd timers.
10. Test backup, off-server copy, restore, and controlled recovery.

## Testing summary

- Client reaches the server through `myserver.test`.
- SSH key authentication works on port 2028.
- NFS write access works from client01.
- NGINX returns `HTTP/2 200` for the project page.
- HTTPS returns `HTTP/2 200` and HTTP redirects to HTTPS.
- Disk monitoring logs OK or WARNING entries based on usage.
- Backup archives are created with matching SHA-256 checksums.
- Backups are copied to client01 and verified there.
- A deleted test page was restored successfully and returned `HTTP/2 200`.
- A stopped NGINX service was detected and recovered automatically.

## Apache vs Nginx comparison

Both Apache and Nginx were tested with the same static project content and
`/health` endpoint. Only one server was bound to port 80 at a time.

See [`docs/apache-nginx-comparison.md`](docs/apache-nginx-comparison.md) for
the full comparison and lab evidence.

NGINX was selected as the final project service because it was already
integrated with the project HTTPS configuration, HTTP-to-HTTPS redirection,
HTTP/2, and health-check automation.

## Troubleshooting highlights

See [`docs/troubleshooting.md`](docs/troubleshooting.md) for documented cases,
including:

- Stale ARP entry preventing client-server communication.
- Port 80 conflict between Apache and NGINX.
- Old Apache virtual host overriding the project site.
- Health-check automation restarting NGINX during the comparison.
- TLS hostname mismatch when using `localhost`.
- Successful restore of a deliberately deleted web page.

## Cloud mapping and next steps

See [`docs/cloud-mapping.md`](docs/cloud-mapping.md) for the mapping between
local lab concepts and AWS services.

Possible next steps include Terraform-based infrastructure provisioning,
AWS EC2 and VPC practice, CloudWatch monitoring, S3-based backups, and
Infrastructure as Code.
