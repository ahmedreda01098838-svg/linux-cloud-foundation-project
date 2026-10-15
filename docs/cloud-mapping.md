# Cloud Mapping

This document maps local lab concepts to equivalent AWS concepts.

| Local lab | AWS mapping | Key distinction |
|---|---|---|
| Fedora Server VM | EC2 instance | EC2 is a cloud VM with IAM, networking, and billing context |
| libvirt virtual network | VPC and subnet | AWS networking is software-defined and managed through AWS controls |
| Static lab IP | Private IP / Elastic IP | Elastic IPs are public IPv4 addresses managed by AWS |
| `/etc/hosts` | Route 53 | Route 53 is managed DNS; `/etc/hosts` is local static mapping |
| firewalld | Security Group | Security Groups are stateful cloud-level controls; a host firewall may still be used |
| SELinux | EC2 host-level security control | IAM controls AWS permissions; it does not replace OS-level mandatory access control |
| SSH key authentication | EC2 key pair | EC2 key pairs are used for initial Linux login; IAM does not replace SSH keys |
| `webadmin` with limited sudo | IAM user/role plus OS user | IAM manages AWS permissions; OS users and sudo manage Linux permissions |
| NFS share | Amazon EFS | EFS is a managed NFS filesystem |
| SCP backup | Amazon S3 | S3 is object storage, not a mounted Linux filesystem by default |
| SHA-256 checksum | S3 checksums / object integrity features | S3 provides additional managed integrity features |
| systemd timer | EventBridge Scheduler | EventBridge Scheduler is a managed scheduling service |
| NGINX/Apache logs | CloudWatch Logs | CloudWatch centralizes logs, metrics, and alarms |
| health-check script | CloudWatch alarm plus Lambda or Systems Manager | Cloud services can automate detection and remediation |
| Manual VM installation | User data / Terraform | Terraform provides reproducible infrastructure provisioning |
| Local Git repository | AWS CodeCommit / GitHub | Both provide version control; GitHub is used in this project |

## Next steps

- Build the same architecture with Terraform.
- Deploy an EC2 instance in a custom VPC.
- Use Security Groups instead of direct firewalld exposure.
- Send NGINX logs to CloudWatch Logs.
- Store verified backups in S3 with lifecycle rules.
- Use EventBridge Scheduler for automated backup jobs.
