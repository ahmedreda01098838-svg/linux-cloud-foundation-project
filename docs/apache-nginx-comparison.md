# Apache vs Nginx Comparison

Both servers were tested with the same static project content and `/health` endpoint.
Only one web server was bound to port 80 at a time.

## Test evidence

| Topic | Apache | Nginx | Lab evidence |
|---|---|---|---|
| Service name | `httpd` | `nginx` | `systemctl is-active` |
| Main configuration | `/etc/httpd/conf/httpd.conf` and `/etc/httpd/conf.d/*.conf` | `/etc/nginx/nginx.conf` and `/etc/nginx/conf.d/*.conf` | Configuration files inspected |
| Project vhost | `/etc/httpd/conf.d/project-site.conf` | `/etc/httpd/conf.d/myserver.test.conf` equivalent at `/etc/nginx/conf.d/myserver.test.conf` | `httpd -S` and `nginx -t` |
| Default content path | `/var/www/html` | `/usr/share/nginx/html` | Default installation paths |
| Project DocumentRoot | `/usr/share/nginx/html` | `/usr/share/nginx/html` | Both served the same custom site |
| Access/error logs | `/var/log/httpd/` | `/var/log/nginx/` | Log directories inspected |
| Health response | `HTTP/1.1 200 OK`, body `OK` | `HTTP/2 200 OK`, body `OK` | `curl` outputs |
| Main page response | `HTTP/1.1 200 OK` | `HTTP/2 200 OK` | `curl -I` outputs |
| TLS | Not configured during this comparison | TLSv1.2/TLSv1.3 with self-signed certificate | NGINX HTTPS configuration |
| SELinux | `httpd_t` running with SELinux Enforcing | Worked with `httpd_sys_content_t` content | `ausearch -m AVC` showed no denials |

## Troubleshooting encountered

1. Apache initially failed to start because NGINX was still listening on port 80.

   Root cause: both services attempted to bind to port 80.

   Solution: stopped and disabled NGINX temporarily before starting Apache.

   Verification: `systemctl is-active httpd` returned `active`.

2. Apache initially served the old Fedora test page instead of the project site.

   Investigation: `sudo httpd -S` showed an old virtual host,
   `/etc/httpd/conf.d/linux-cloud-site.conf`, configured as the default server
   with `DocumentRoot /srv/linux-cloud-site`.

   Root cause: requests to `localhost` did not match `ServerName myserver.test`,
   so Apache used the old default virtual host.

   Solution: temporarily renamed the old configuration file to
   `linux-cloud-site.conf.bak` and restarted Apache.

   Verification: `httpd -S` showed only the `myserver.test` virtual host, and
   Apache returned the project page.

3. NGINX automatically restarted during the Apache test.

   Root cause: `project-healthcheck.timer` detected NGINX as stopped and
   restarted it, causing another port 80 conflict.

   Solution: temporarily stopped `project-healthcheck.timer` during the Apache
   comparison.

   Verification: NGINX remained inactive while Apache was tested.

## Practical observation

Both Apache and Nginx successfully served the same static project content and
health endpoint. In this small lab, both returned `HTTP 200` for the main page,
`/health`, and `restore-test.html`.

Nginx was selected as the final project service because it was already
integrated with the project HTTPS configuration, HTTP-to-HTTPS redirection,
HTTP/2, and the health-check automation.

No performance superiority is claimed from this small lab test.
