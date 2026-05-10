<!-- ────────────────────────────────────────────────────────────── -->
<!--           README.md · terraform-ecs-platform                    -->
<!--   Enterprise AWS ECS Fargate + RDS PostgreSQL + Secrets Mgr    -->
<!-- ────────────────────────────────────────────────────────────── -->

<h1 align="center">
  🐳 terraform‑ecs‑platform
</h1>

<p align="center">
  <strong>Production‑grade, highly‑available container platform on AWS</strong><br>
  ECS Fargate (ARM64) · PostgreSQL RDS · Secrets Manager · WAF · CI/CD
</p>

<p align="center">
  <img src="https://img.shields.io/badge/terraform-%3E%3D1.5-623CE4?logo=terraform" alt="Terraform >= 1.5">
  <img src="https://img.shields.io/badge/AWS_Provider-~%3E5.0-FF9900?logo=amazonaws" alt="AWS Provider ~> 5.0">
  <img src="https://img.shields.io/badge/Architecture-ARM64-0091BD" alt="ARM64 Architecture">
  <img src="https://img.shields.io/badge/Well‑Architected-✅-green" alt="AWS Well-Architected">
  <img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="MIT License">
</p>

---

## 📖 Table of Contents

1. [Overview](#-overview)
2. [Architecture Diagram](#-architecture-diagram)
3. [Key Features](#-key-features)
4. [Repository Structure](#-repository-structure)
5. [Prerequisites](#-prerequisites)
6. [Quick Start](#-quick-start)
7. [Variables Reference](#-variables-reference)
8. [Module Documentation](#-module-documentation)
9. [CI/CD Pipeline](#-cicd-pipeline)
10. [Security Deep‑Dive](#-security-deep-dive)
11. [High Availability](#-high-availability)
12. [Cost Optimisation](#-cost-optimisation)
13. [Troubleshooting](#-troubleshooting)
14. [Production Hardening Checklist](#-production-hardening-checklist)
15. [License](#-license)

---

## 🧭 Overview

This repository contains a **complete Infrastructure‑as‑Code (IaC) solution** for deploying
a containerised application on **AWS ECS Fargate** backed by a managed **PostgreSQL RDS**
database.  Every component is built following the
[AWS Well‑Architected Framework](https://aws.amazon.com/architecture/well-architected/) across
all six pillars: **Operational Excellence, Security, Reliability, Performance Efficiency,
Cost Optimisation, and Sustainability.**

| Layer | Technology | Purpose |
|-------|-----------|---------|
| **Compute** | ECS Fargate (ARM64 Graviton) | Run containerised workloads without managing servers |
| **Database** | Amazon RDS for PostgreSQL 16.4 (Multi‑AZ) | Relational data store with automatic failover |
| **Load Balancing** | Application Load Balancer (ALB) | Distribute traffic across Availability Zones |
| **Secrets** | AWS Secrets Manager + Python Lambda rotation | Store and automatically rotate database credentials |
| **Networking** | Custom VPC / 2 AZs / NAT Gateways | Isolated public, private, and database subnets |
| **Security** | Security Groups, WAF, IAM, Encryption | Defence‑in‑depth across all layers |
| **Observability** | CloudWatch Logs, Container Insights, Alarms | Centralised logging and proactive alerting |
| **CI/CD** | GitHub Actions + OIDC | Automated plan on PR, apply on merge to `main` |

---

## 🏛 Architecture Diagram

### Mermaid (render on GitHub)

```mermaid
graph TB
    subgraph Internet["Internet"]
        User["👤 Users"]
    end

    subgraph AWS["AWS Cloud (ap-south-1)"]
        subgraph VPC["VPC 10.0.0.0/16"]
            subgraph Public["Public Subnets (AZ-a & AZ-b)"]
                IGW["Internet Gateway"]
                NATa["NAT Gateway (AZ-a)"]
                NATb["NAT Gateway (AZ-b)"]
                ALB["Application Load Balancer"]
            end

            subgraph PrivateECS["Private ECS Subnets (AZ-a & AZ-b)"]
                TaskA["ECS Fargate Task (AZ-a)"]
                TaskB["ECS Fargate Task (AZ-b)"]
            end

            subgraph PrivateDB["Private DB Subnets (AZ-a & AZ-b)"]
                RDSpri["RDS PostgreSQL (Primary)"]
                RDSstb["RDS PostgreSQL (Standby)"]
                Proxy["RDS Proxy"]
            end
        end

        Secrets["AWS Secrets Manager"]
        CW["Amazon CloudWatch"]
        WAF["AWS WAF"]
    end

    User --> ALB
    ALB --> WAF
    ALB --> TaskA & TaskB
    TaskA & TaskB --> Proxy
    Proxy --> RDSpri
    RDSpri <--> RDSstb
    TaskA & TaskB -.-> Secrets
    TaskA & TaskB -.-> CW
    NATa & NATb -.-> TaskA & TaskB

ASCII (always visible)

                        ┌─────────────────────┐
                        │    Internet 🌐      │
                        └─────────┬───────────┘
                                  │
                    ┌─────────────▼─────────────┐
                    │  Internet Gateway         │
                    └─────────────┬─────────────┘
                                  │
              ┌───────────────────┴───────────────────┐
              │                                       │
    ┌─────────▼─────────┐                   ┌─────────▼─────────┐
    │ Public Subnet AZ‑a │                   │ Public Subnet AZ‑b │
    │ 10.0.1.0/24        │                   │ 10.0.2.0/24        │
    │ ┌───────────────┐  │                   │ ┌───────────────┐  │
    │ │ NAT Gateway   │  │                   │ │ NAT Gateway   │  │
    │ └───────────────┘  │                   │ └───────────────┘  │
    │ ┌───────────────┐  │                   │ ┌───────────────┐  │
    │ │ ALB (public)   │  │                   │ │ ALB (public)   │  │
    │ └───────┬───────┘  │                   │ └───────┬───────┘  │
    └─────────┼──────────┘                   └─────────┼──────────┘
              │                                       │
    ┌─────────▼─────────┐                   ┌─────────▼─────────┐
    │ Private ECS AZ‑a  │                   │ Private ECS AZ‑b  │
    │ 10.0.10.0/24       │                   │ 10.0.11.0/24       │
    │ ┌───────────────┐  │                   │ ┌───────────────┐  │
    │ │ Fargate Task  │  │                   │ │ Fargate Task  │  │
    │ └───────┬───────┘  │                   │ └───────┬───────┘  │
    └─────────┼──────────┘                   └─────────┼──────────┘
              │                                       │
    ┌─────────▼──────────┐                  ┌─────────▼──────────┐
    │ Private DB AZ‑a    │                  │ Private DB AZ‑b    │
    │ 10.0.20.0/24        │                  │ 10.0.21.0/24        │
    │ ┌────────────────┐  │                  │ ┌────────────────┐  │
    │ │ RDS Primary +  │◄─┼──────────────────┼─┤ RDS Standby    │  │
    │ │ RDS Proxy      │  │   synchronous    │ │                │  │
    │ └────────────────┘  │   replication    │ └────────────────┘  │
    └─────────────────────┘                  └─────────────────────┘

    Secrets Manager ◄── ECS tasks (read credentials)
    CloudWatch     ◄── ECS, RDS, ALB (logs & metrics)
    WAF            ◄── ALB (web ACL)

    ✨ Key Features
🔐 Security
WAF – AWS Managed Core Rule Set attached to ALB.

Secrets Manager – No hard‑coded credentials; automatic 30‑day rotation via Python Lambda.

Encryption – RDS storage encrypted (KMS), S3 buckets SSE‑AES256, Terraform state encrypted.

Least‑privilege IAM – ECS Task Role can read only the specific database secret.

Security Groups – ALB → ECS → RDS chain; no direct internet access to compute or DB.

Deletion Protection – Enabled on ALB and RDS.

🚀 High Availability
Multi‑AZ RDS with synchronous standby and automatic failover.

ECS tasks spread across 2 Availability Zones with ALB health‑based routing.

NAT Gateway per AZ – no single point of failure for outbound traffic.

RDS Proxy – connection pooling with seamless failover handling.

Deployment Circuit Breaker – automatic rollback on failed ECS deployments.

📈 Auto Scaling
CPU tracking – target 60% average utilisation.

Memory tracking – target 70% average utilisation.

Request‑count tracking – ALBRequestCountPerTarget with target 1000 req/target.

Cooldown windows of 60 seconds for both scale‑in and scale‑out.

👁 Observability
Container Insights enabled on ECS cluster.

CloudWatch Logs for ECS tasks (configurable retention, default 30 days).

RDS logs exported to CloudWatch (postgresql).

Performance Insights enabled on RDS (7‑day retention).

Enhanced Monitoring at 60‑second granularity.

CloudWatch Alarm for ECS CPU > 80%.

🧩 Infrastructure as Code
Terraform >= 1.5 with remote state (S3 + intrinsic locking).

Fully modular – six reusable, documented modules.

No deprecated patterns – aws_iam_role_policy_attachment used instead of inline managed_policy_arns.

ARM64 Graviton for both ECS tasks and RDS instances – better price/performance.

CI/CD ready – GitHub Actions workflow included (OIDC, plan on PR, apply on merge).

📁 Repository Structure
terraform-ecs-platform/
├── .github/
│   └── workflows/
│       └── terraform.yml            # CI/CD pipeline
├── module/
│   ├── alb/
│   │   ├── main.tf                  # ALB, target group, listeners, WAF, S3 logging
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── ecs/
│   │   ├── main.tf                  # ECS cluster, service, task def, auto‑scaling, alarms
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── templates/
│   │       └── task-definition.json.tpl
│   ├── iam/
│   │   ├── main.tf                  # ECS execution & task roles, secrets read policy
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── rds/
│   │   ├── main.tf                  # RDS instance, proxy, secrets, rotation Lambda
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── rotation_lambda/
│   │       └── lambda_function.py   # Python Secrets Manager rotation handler
│   ├── security-groups/
│   │   ├── main.tf                  # ALB, ECS, RDS, and Lambda security groups
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── vpc/
│       ├── main.tf                  # VPC, subnets, NAT GWs, route tables
│       ├── variables.tf
│       └── outputs.tf
├── .gitignore
├── .terraform.lock.hcl              # Provider version lock (commit this!)
├── backend.hcl.example              # Backend config template
├── backend.tf                       # S3 backend declaration
├── locals.tf                        # Common tags
├── main.tf                          # Root module – wires everything together
├── outputs.tf                       # ALB DNS, RDS endpoint, secret ARN
├── providers.tf                     # AWS provider + assume‑role support
├── terraform.tfvars.example         # Variable values template
├── variables.tf                     # All input variable declarations
└── versions.tf                      # Terraform & provider version constraints

✅ Prerequisites
Requirement	Minimum Version	Notes
Terraform	>= 1.5.0	Install guide
AWS CLI	>= 2.0	Configured with credentials (aws configure)
AWS Account	–	Permissions to create VPC, ECS, RDS, IAM, Secrets Manager, Lambda
S3 Bucket	–	For remote state (must exist before terraform init)
GitHub	–	For CI/CD pipeline (OIDC role ARN needed in workflow)

🚀 Quick Start
1. Clone the repository
git clone https://github.com/adityaphadnisops/terraform-ecs-platform.git
cd terraform-ecs-platform

2. Create the S3 backend bucket (one‑time)
aws s3api create-bucket \
  --bucket YOUR_UNIQUE_STATE_BUCKET \
  --region ap-south-1 \
  --create-bucket-configuration LocationConstraint=ap-south-1

aws s3api put-bucket-versioning \
  --bucket YOUR_UNIQUE_STATE_BUCKET \
  --versioning-configuration Status=Enabled

aws s3api put-bucket-encryption \
  --bucket YOUR_UNIQUE_STATE_BUCKET \
  --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'

  3. Configure the backend
  cp backend.hcl.example backend.hcl

  Edit backend.hcl with your actual bucket name:

  bucket         = "YOUR_UNIQUE_STATE_BUCKET"
key            = "ecs-platform/terraform.tfstate"
region         = "ap-south-1"
use_lockfile   = true
encrypt        = true

4. Configure variables
cp terraform.tfvars.example terraform.tfvars

Edit terraform.tfvars with your values (minimum: alb_logs_bucket must be globally unique):

aws_region              = "ap-south-1"
environment             = "prod"
project_name            = "ecs-platform"
alb_logs_bucket         = "my-globally-unique-alb-logs-bucket"  # CHANGE THIS!
certificate_arn         = ""              # Set for HTTPS
enable_waf              = true

5. Deploy

terraform init -backend-config=backend.hcl
terraform fmt -recursive
terraform validate
terraform plan -out=tfplan      # Review the plan carefully
terraform apply tfplan

6. Verify
After ~10 minutes, note the outputs:
terraform output

alb_dns_name        = "ecs-platform-alb-1234567890.ap-south-1.elb.amazonaws.com"
rds_endpoint        = "ecs-platform-proxy.proxy-xxx.ap-south-1.rds.amazonaws.com"
database_secret_arn = "arn:aws:secretsmanager:ap-south-1:123456789012:secret:ecs-platform-db-credentials-xxxxx"

Open http://<alb_dns_name> in your browser – you should see the Nginx welcome page.

📋 Variables Reference
Required (must be changed from defaults)

Variable: alb_logs_bucket
Default: my-alb-logs-unique-bucket
Description: Globally unique S3 bucket name for ALB access logs

Networking

Variable: vpc_cidr
Default: 10.0.0.0/16
Description: 10.0.0.0/16

Variable: public_subnets
Default: ["10.0.1.0/24","10.0.2.0/24"] 
Description: Public subnet CIDRs

Variable: private_ecs_subnets
Default: ["10.0.10.0/24","10.0.11.0/24"]
Description: ECS private subnet CIDRs

Variable: private_db_subnets
Default: ["10.0.20.0/24","10.0.21.0/24"]
Description: Database private subnet CIDRs

# Compute

Variable: container_image  
Default: public.ecr.aws/nginx/nginx:latest  
Description: Container image (ARM64 compatible)

---

Variable: container_port  
Default: 80  
Description: Application port exposed by the container

---

Variable: ecs_task_cpu  
Default: 1024  
Description: CPU units for ECS task (1024 = 1 vCPU)

---

Variable: ecs_task_memory  
Default: 2048  
Description: Memory allocation for ECS task in MiB

---

Variable: ecs_desired_count  
Default: 2  
Description: Desired number of ECS tasks

---

Variable: ecs_min_count  
Default: 1  
Description: Minimum ECS tasks for auto scaling

---

Variable: ecs_max_count  
Default: 4  
Description: Maximum ECS tasks for auto scaling

---

Variable: ecs_cpu_target  
Default: 60  
Description: CPU utilisation target (%) for ECS auto scaling

📦 Module Documentation
module/vpc
Creates a VPC with DNS support, Internet Gateway, NAT Gateways (one per AZ), public/private ECS/private DB subnets, and route tables. Subnets are automatically mapped to the first two AZs of the region.

Outputs: vpc_id, public_subnet_ids, private_ecs_subnet_ids, private_db_subnet_ids, nat_gateway_ids

module/security-groups
Creates four security groups:

ALB – allows inbound 80/443 from anywhere, all outbound.

ECS – allows inbound only from ALB SG on the container port, all outbound (via NAT).

RDS – allows inbound 5432 only from ECS SG and rotation Lambda SG.

Rotation Lambda – no inbound rules, all outbound.

Outputs: alb_sg_id, ecs_sg_id, rds_sg_id, rotation_lambda_sg_id

module/iam
Creates ECS execution role (with AmazonECSTaskExecutionRolePolicy for ECR pulls + CloudWatch logs) and ECS task role (with a scoped policy allowing GetSecretValue and DescribeSecret on only the database secret ARN).

Outputs: ecs_execution_role_arn, ecs_task_role_arn

module/alb
Creates an internet‑facing ALB with HTTP listener (and optional HTTPS), target group with health checks, S3 access logging (encrypted, private), and an optional AWS WAF Web ACL with the AWSManagedRulesCommonRuleSet.

Outputs: alb_dns_name, target_group_arn, alb_arn, alb_arn_suffix, target_group_arn_suffix

module/ecs
Creates an ECS Fargate cluster (Container Insights enabled), task definition (ARM64, awsvpc network mode, awslogs driver, health check, secrets injection), ECS service (rolling deployment, circuit breaker), auto‑scaling target with CPU, memory, and request‑count policies, CloudWatch log group, and a CPU high alarm.

Outputs: cluster_name, service_name, task_definition_arn

module/rds
Creates a PostgreSQL RDS instance (Multi‑AZ, encrypted gp3 storage, Performance Insights, Enhanced Monitoring, deletion protection), an RDS Proxy (connection pooling, TLS required), a Secrets Manager secret with the master credentials, and a Python 3.12 Lambda function for automatic 30‑day password rotation.

Outputs: database_endpoint (proxy endpoint), database_secret_arn, database_id


# Database

Variable: database_name  
Default: appdb  
Description: Initial PostgreSQL database name

---

Variable: rds_engine_version  
Default: 16.4  
Description: PostgreSQL engine version

---

Variable: rds_instance_class  
Default: db.t4g.medium  
Description: ARM64 Graviton RDS instance type

---

Variable: rds_allocated_storage  
Default: 20  
Description: Allocated database storage in GB (gp3)

---

Variable: rds_multi_az  
Default: true  
Description: Enables Multi-AZ deployment for high availability

---

Variable: rds_master_username  
Default: dbadmin  
Description: Master username for PostgreSQL

---

Variable: rds_backup_retention  
Default: 7  
Description: Automated backup retention period in days

---

🔄 CI/CD Pipeline
The repository includes a GitHub Actions workflow (.github/workflows/terraform.yml):

name: "Terraform CI/CD"
on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  terraform:
    runs-on: ubuntu-latest
    permissions:
      id-token: write       # Required for OIDC
      contents: read
    steps:
      - uses: actions/checkout@v4
      - uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::ACCOUNT_ID:role/github-actions-terraform
          aws-region: ap-south-1
      - uses: hashicorp/setup-terraform@v3
      - run: terraform init -backend-config=backend.hcl
      - run: terraform fmt -check -recursive
      - run: terraform validate
      - if: github.ref == 'refs/heads/main'
        run: terraform apply -auto-approve

Setup required:

Create an IAM role (github-actions-terraform) with a trust policy for GitHub OIDC.

Attach sufficient permissions (VPC, ECS, RDS, IAM, Secrets Manager, Lambda).

Update role-to-assume in the workflow with your account ID.

⚠️ The terraform apply step runs automatically on push to main. For production, consider adding a manual approval step or an environment protection rule.







🛡 High Availability
RDS Multi‑AZ: Synchronous standby in a different AZ; automatic failover in ~60‑120 seconds.

RDS Proxy: Maintains warm connection pools; survives failovers without application disruption.

ECS across 2 AZs: ALB health checks route traffic only to healthy tasks; unhealthy tasks are replaced.

NAT Gateway per AZ: If one AZ fails, the other NAT Gateway continues serving its private subnets.

Deployment Circuit Breaker: If a new deployment causes repeated task failures, ECS automatically rolls back.

Auto Scaling: Three policies (CPU, memory, ALB request count) ensure capacity matches demand.


# Security

Variable: certificate_arn  
Default: ""  
Description: ACM certificate ARN for HTTPS (empty = HTTP only)

---

Variable: enable_waf  
Default: true  
Description: Enables AWS WAF managed rules on ALB

---

Variable: terraform_role_arn  
Default: ""  
Description: IAM role ARN for Terraform assume-role access (CI/CD)

---

# Observability

Variable: log_retention_days  
Default: 30  
Description: CloudWatch log retention period in days

---

# Security Deep-Dive

Control: Network isolation  
Implementation: ECS tasks and RDS run in private subnets; only ALB is internet-facing

---

Control: Security group chain  
Implementation: ALB SG → ECS SG → RDS SG with strict least-privilege rules

---

Control: Secrets management  
Implementation: Database credentials stored in AWS Secrets Manager only

---

Control: Automatic rotation  
Implementation: Python Lambda rotates RDS credentials every 30 days

---

Control: Encryption at rest  
Implementation: RDS, S3 buckets, and Terraform state encrypted using SSE/KMS

---

Control: Encryption in transit  
Implementation: ALB HTTPS-ready with ACM certificate support

---

Control: WAF protection  
Implementation: AWS Managed Core Rule Set protects against OWASP Top 10

---

Control: IAM least privilege  
Implementation: ECS task role scoped to only required Secrets Manager ARN

---

Control: Deletion protection  
Implementation: Enabled on ALB and RDS to prevent accidental deletion

---

Control: Public access block  
Implementation: S3 buckets block all public ACLs and public policies

---

# Cost Optimisation

Decision: ARM64 (Graviton)  
Rationale: Better price/performance compared to x86 for ECS and RDS

---

Decision: Fargate serverless compute  
Rationale: No EC2 management overhead; pay only for running tasks

---

Decision: gp3 storage  
Rationale: Lower baseline storage cost with burstable IOPS

---

Decision: RDS Proxy  
Rationale: Reduces database connections and improves scalability

---

Decision: Auto Scaling  
Rationale: Scales in during low traffic and scales out during spikes

---

Decision: NAT Gateway per AZ  
Rationale: Avoids cross-AZ NAT traffic charges and improves availability

---

Decision: Log retention  
Rationale: Default 30-day retention reduces long-term CloudWatch costs

---

# Troubleshooting

Issue: terraform init fails with “S3 bucket does not exist”  
Cause: Backend S3 bucket not created  
Fix: Create the backend bucket manually before running terraform init

---

Issue: terraform validate fails with “Module not installed”  
Cause: terraform init was not executed with backend config  
Fix: Re-run using terraform init -backend-config=backend.hcl

---

Issue: ALB health checks failing  
Cause: Container not listening on configured port  
Fix: Ensure container exposes the same port as var.container_port

---

Issue: ECS tasks stuck in PENDING  
Cause: NAT Gateway route missing or SG blocks outbound traffic  
Fix: Verify private route tables have NAT access

---

Issue: Container cannot connect to RDS  
Cause: Security group mismatch  
Fix: Ensure RDS SG allows ingress from ECS SG on port 5432

---

Issue: Secrets rotation fails  
Cause: Lambda VPC networking issue  
Fix: Ensure Lambda subnets can access RDS and Secrets Manager

---

Issue: terraform plan shows unexpected destruction  
Cause: State drift or manual infrastructure changes  
Fix: Run terraform refresh before planning again