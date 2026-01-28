# Local Cloud Sandbox (LocalStack + Terraform + Ansible + Pulumi)

A hostile-by-default, browser-based Linux sandbox for practicing AWS workflows using LocalStack. This project demonstrates platform engineering fundamentals: security hardening, isolation, repeatable automation, IAM best practices, and developer enablement.

## Highlights
- Non-root sandbox with read-only root FS
- No Docker socket, no capabilities, no privilege escalation
- Internal-only network (egress blocked by default)
- Resource limits for abuse prevention
- Pre-seeded Terraform, Pulumi, and Ansible examples
- HA, multi-region reference stacks with security guardrails

## What's Included
- Terraform HA stack: two-region VPCs, public/private subnets, IGWs, NAT gateways, ALB + Auto Scaling, RDS (multi-AZ), Route 53 private DNS, S3 with security guardrails
- Ansible role: create bucket + upload object against LocalStack
- Pulumi project (Python): matching HA stack with simulated and full modes
- Runbooks, architecture docs, and security model

## Docs
- `docs/architecture.md`
- `docs/security.md`
- `docs/runbook.md`
- `docs/diagram.mmd`
- `docs/iac-explained.md`

## Commands
```
make health
make smoke
make logs
make clean
```

## Skill Set Demonstrated
- Container hardening & isolation
- Network segmentation and egress control
- Infrastructure as Code patterns (modules)
- Configuration management (roles)
- Operational tooling and runbooks
