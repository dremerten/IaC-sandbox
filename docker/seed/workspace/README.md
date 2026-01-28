# Local Cloud Sandbox Practice Guide

Use this sandbox to practice a full HA AWS-style deployment using LocalStack with Terraform, Pulumi, and Ansible.
Work is ephemeral and confined to the sandbox workspace.

What you get
- A real terminal session in the browser, no host access.
- LocalStack as the AWS API endpoint.
- Terraform, Pulumi (Python), and Ansible, all pre-installed and offline-friendly.
- Two side-by-side HA stacks (primary + secondary regions) with best-practice security defaults.

Allowed commands
```
help
aws
terraform
tf-init
tf-apply
ansible
ansible-playbook
ansible-run
pulumi
pulumi-python
vim
make
mkdir
rm
chmod
sleep
ls
cat
pwd
whoami
id
```

Accessing code
You can `cd` into the project directories and edit files with `vim`:
```
cd terraform
vim main.tf
cd ../ansible
vim playbook.yml
cd ../pulumi/python
vim __main__.py
```

Quick check (AWS CLI)
```
aws sts get-caller-identity
aws s3api list-buckets
```

Sandbox health checks
```
make health
make smoke
```

Terraform HA practice (LocalStack)
The Terraform stack provisions a full HA layout in two regions:
- VPCs, public/private subnets, IGWs, and NAT gateways
- ALB + Auto Scaling (private app tier behind a public ALB)
- RDS (multi-AZ), private DNS via Route 53, and S3 with security guardrails
- IAM roles and instance profile for least-privilege access

Security defaults include S3 public access blocks, bucket ownership enforcement, server-side encryption, IMDSv2 on instances, and encrypted RDS with backups.

By default, `simulate_unsupported` is `true` to avoid LocalStack Community gaps.
The AWS provider is bundled in the image for offline use.

Run (simulated mode, default):
```
make tf-init
make tf-apply
terraform output
```

Full HA mode (may require LocalStack Pro):
```
make tf-init
tf-apply -var=simulate_unsupported=false
terraform output
```

Ansible practice (LocalStack)
```
make ansible-run
```

Pulumi practice (LocalStack)
The Python project lives in `pulumi/python`. The default stack uses `simulateUnsupported: true` so LocalStack Community can run without errors.

Python:
```
make pulumi-python-up
make pulumi-python-destroy
```

Pulumi full HA (may require LocalStack Pro)
```
make pulumi-python-full-up
make pulumi-python-full-destroy
```

Expected behavior and limitations
- LocalStack Community may not support every service used in the full HA layout. Use simulated mode by default.
- All resources are created in LocalStack only. No real AWS account or credentials are required.
- Workspace code resets to defaults on each new login (including page refresh).
