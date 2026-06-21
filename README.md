# Cloudride DevOps Assessment

A production-ready containerized microservices stack on **AWS ECS Fargate**, provisioned entirely with **Terraform** and deployed via a **GitHub Actions CI/CD pipeline** with zero-downtime rolling updates.

**Live URL:** `http://<ALB_DNS_NAME>` *(replace with ALB DNS after deployment)*

---

## Table of Contents

- [Architecture Overview](#architecture-overview)
- [Services](#services)
- [Infrastructure Components](#infrastructure-components)
- [CI/CD Pipeline](#cicd-pipeline)
- [Design Decisions](#design-decisions)
- [AWS Well-Architected Framework](#aws-well-architected-framework)
- [Getting Started](#getting-started)
- [AI Tools Used](#ai-tools-used)

---

## Architecture Overview

```
                          ┌─────────────────────────────────────────────────────────┐
                          │                        VPC (10.0.0.0/16)                │
                          │                                                         │
Internet ──► IGW ──►  ┌──┴──────────────────────────────────────────────────────┐  │
                       │          Public Subnets  (us-east-1a / us-east-1b)     │  │
                       │   ┌─────────────────────────────┐   ┌───────────────┐  │  │
                       │   │       ALB (port 80)          │   │  NAT Gateway  │  │  │
                       │   └──────────────┬──────────────┘   └───────┬───────┘  │  │
                       └─────────────────-│────────────────────────--│──────────┘  │
                          │               │                           │             │
                          │  ┌────────────┴──────────────────────────▼──────────┐  │
                          │  │         Private Subnets (us-east-1a / us-east-1b)│  │
                          │  │                                                   │  │
                          │  │   ┌────────────────────┐   ┌──────────────────┐  │  │
                          │  │   │  nginx-docker       │   │  api-service     │  │  │
                          │  │   │  (ECS Fargate)      │──►│  (ECS Fargate)   │  │  │
                          │  │   │  2–4 tasks          │   │  3–4 tasks       │  │  │
                          │  │   │  Port 80            │   │  Port 80         │  │  │
                          │  │   └────────────────────┘   └──────────────────┘  │  │
                          │  │          Service Connect (api-service.local)      │  │
                          │  └───────────────────────────────────────────────────┘  │
                          └─────────────────────────────────────────────────────────┘

  GitHub Actions ──► ECR ──► ECS Task Definition Update ──► Rolling Deploy
```

**Traffic flow:**
1. User hits the ALB on port 80
2. ALB forwards to `nginx-docker` tasks (HTML frontend)
3. Frontend JavaScript calls `/api/*` endpoints
4. Nginx routes `/api/*` to `api-service` via **AWS Service Connect** (`api-service.local`)
5. `api-service` responds with JSON (hello, health, status)

---

## Services

### `nginx-docker` — Frontend

| Property | Value |
|---|---|
| Base image | `nginx:latest` |
| Port | 80 |
| Desired tasks | 2 (min 2, max 4) |
| ALB attached | Yes |
| Service Connect DNS | `nginx-docker.local` |

Serves a simple HTML page that fetches data from the API service and displays it live. The `API_BASE_URL` environment variable is injected at container startup via `envsubst`, making the service portable across environments.

### `api-service` — Backend

| Property | Value |
|---|---|
| Runtime | Python 3.13-alpine + Flask + Gunicorn |
| Port | 80 |
| Desired tasks | 2 (min 3, max 4) |
| ALB attached | No (internal only) |
| Service Connect DNS | `api-service.local` |

Exposes three endpoints:

| Endpoint | Description |
|---|---|
| `GET /` or `/api/health` | Returns `{"status": "healthy"}` |
| `GET /api/hello` | Returns greeting with timestamp and service name |
| `GET /api/status` | Returns uptime and current timestamp |

---

## Infrastructure Components

### Network

| Resource | Details |
|---|---|
| VPC | `10.0.0.0/16` |
| Public subnets | 2 × `/24` across 2 AZs — hosts ALB and NAT Gateway |
| Private subnets | 2 × `/24` across 2 AZs — hosts all ECS tasks |
| Internet Gateway | Single IGW for public subnet egress |
| NAT Gateway | Single NAT in public subnet; private subnets route outbound traffic through it |
| Route tables | Separate public (→ IGW) and private (→ NAT) route tables |

### Security Groups

| Group | Inbound | Outbound |
|---|---|---|
| `security_group_alb` | Port 80 from `0.0.0.0/0` | All traffic |
| `security_group_tasks` | Port 80 + ICMP from ALB SG | All traffic |

### Load Balancer

- **Type:** Application Load Balancer (internet-facing)
- **Listener:** HTTP port 80 → forwards to ECS target group
- **Target type:** IP (required for Fargate `awsvpc` networking)
- **Health checks:** Default HTTP `/`

### ECS / Fargate

- **Cluster:** Single shared cluster for all services
- **Launch type:** Fargate (fully serverless — no EC2 to manage)
- **Task resources:** 256 CPU units / 512 MB RAM per task
- **Networking:** `awsvpc` mode — each task gets its own ENI in a private subnet
- **Service discovery:** AWS Service Connect with an HTTP namespace; services reach each other by short DNS name (e.g., `api-service.local`)
- **Logging:** CloudWatch Logs per service (`/ecs/<service-name>`, 30-day retention)

### Auto-Scaling

Both services scale on **ECS Average CPU Utilization**:

| Service | Min | Max | Target CPU | Scale-out cooldown | Scale-in cooldown |
|---|---|---|---|---|---|
| `nginx-docker` | 2 | 4 | 60% | 60 s | 300 s |
| `api-service` | 3 | 4 | 60% | 60 s | 300 s |

### Container Registry (ECR)

- One private ECR repository per service
- **Image tag mutability:** IMMUTABLE (prevents tag overwrites for any tag except `latest*`)
- Images are tagged with the **Git commit SHA** on every deployment

### Terraform State

- **Backend:** S3 with versioning enabled
- **Locking:** Native S3 lock file (`use_lockfile = true`)
- **Workspaces:** Separate state files for `prod` and `dev` environments

---

## CI/CD Pipeline

### Workflows

| Workflow | Trigger | Environment |
|---|---|---|
| `main-deployment.yaml` | Push to `main` | `prod` |
| `dev-pr.yaml` | Pull request to `main` | `dev` |

### Authentication — Keyless OIDC

GitHub Actions authenticates to AWS using **OpenID Connect** — no long-lived AWS credentials are stored as GitHub secrets. The workflow requests a short-lived OIDC token from GitHub and exchanges it for temporary AWS credentials by assuming the IAM role `github-actions-ecr-runner-role`.

The trust policy restricts access to repositories in the `NachmanM` GitHub organization only.

### Deployment Flow

```
git push main
    │
    ▼
GitHub Actions (OIDC → AWS IAM role)
    │
    ├── docker build + docker push → ECR  (tagged with github.sha)
    │
    └── terraform apply
            -target aws_ecs_task_definition.main   (new revision with new image tag)
            -target aws_ecs_service.main            (rolling update)
```

### Zero-Downtime Deployment

ECS performs a **rolling update** by default:
- Launches new tasks with the updated image
- Waits for new tasks to pass ALB health checks
- Only then drains and stops old tasks
- At no point does task count drop below `desired_count`

The IAM role used by GitHub Actions is scoped to the minimum permissions needed: ECR push, ECS task definition updates, service updates, and Terraform state access.

---

## Design Decisions

### Fargate over EC2

ECS Fargate eliminates the need to manage, patch, or right-size EC2 instances. For a demo workload at this scale, the operational simplicity outweighs the slightly higher per-task cost.

### Single NAT Gateway

A single NAT Gateway is cost-effective for this assessment. In a multi-AZ production setup, a NAT Gateway per AZ would eliminate cross-AZ egress charges and provide higher availability.

### AWS Service Connect for Internal Communication

Rather than using plain DNS, environment variables, or a separate service mesh, AWS Service Connect provides built-in client-side load balancing, observability metrics, and automatic deregistration when tasks stop — all with zero additional infrastructure.

### Terraform Workspaces for Environment Isolation

Using `terraform workspace` with a shared backend gives each environment (`dev`, `prod`) its own isolated state file without duplicating module code. Resource names are automatically prefixed with the workspace name (e.g., `prod-default-project-name`).

### Terraform `local_exec` for Docker Builds

Docker builds are triggered from within Terraform using `terraform_data` + `local-exec` provisioners. This keeps the build and deploy tightly coupled — the ECR push and task definition update happen in the same `terraform apply` run, ensuring the image always exists before the task definition references it.

### Modular Terraform Structure

Each concern is isolated into its own module:

| Module | Responsibility |
|---|---|
| `network_infra` | VPC, subnets, IGW, NAT, route tables, security groups |
| `alb` | Application Load Balancer, listeners, target groups |
| `ecs_cluster_wide` | ECS cluster, Service Connect namespace |
| `ecs_stack` | Task definitions, services, ECR repos, auto-scaling, CloudWatch logs |
| `aws_oidc` | GitHub Actions IAM role and OIDC provider |
| `s3_state` | Terraform remote state bucket |

---

## AWS Well-Architected Framework

### Operational Excellence
- Infrastructure defined entirely as code (Terraform) — reproducible, reviewable, and version-controlled
- CloudWatch Logs for all ECS tasks with a 30-day retention policy
- CI/CD pipeline automates every deployment; no manual steps after `git push`

### Security
- ECS tasks run in **private subnets** — no direct internet exposure
- Only the ALB is internet-facing; tasks are only reachable through it
- GitHub Actions uses **keyless OIDC** authentication — no static credentials in GitHub secrets
- IAM role for CI/CD follows **least-privilege**: scoped to ECR push, ECS updates, and state bucket access only
- ECR image tags are **immutable** to prevent tag overwriting

### Reliability
- ECS services span **two Availability Zones**, so an AZ failure does not take down the service
- Auto-scaling ensures the application handles traffic spikes without manual intervention
- Rolling deployments guarantee that healthy tasks serve traffic throughout every release
- S3 state backend with **versioning** protects against accidental state corruption

### Performance Efficiency
- Fargate tasks are sized conservatively (256 CPU / 512 MB) and scale out automatically on CPU pressure
- The `api-service` has a higher minimum task count (3) since it is the shared backend for all frontend tasks
- Alpine-based images (`python:3.13-alpine`) minimize cold-start times

### Cost Optimization
- Fargate: pay only for running task CPU and memory — no idle EC2 capacity
- Single NAT Gateway (acceptable for non-production; per-AZ NAT recommended for production)
- CloudWatch log retention capped at 30 days to avoid unbounded log storage costs
- ECR lifecycle policies can be added to prune old untagged images

---

## Getting Started

### Prerequisites

- AWS CLI configured with credentials for the target account
- Terraform >= 1.15.6
- Docker (for local builds)
- Bash

### Bootstrap (first-time setup)

```bash
# Clone the repo
git clone https://github.com/NachmanM/<repo-name>
cd <repo-name>

# Run the bootstrap script — provisions both dev and prod environments
./init.sh
```

The `init.sh` script runs four sequential phases:

| Phase | Backend | Workspace | Action |
|---|---|---|---|
| 1 | local | `dev` | Imports the GitHub OIDC provider; provisions all infra (VPC, ALB, ECS, ECR, S3 state bucket) |
| 2 | s3 | `dev` | Migrates the local state into the S3 remote backend |
| 3 | s3 | `dev` | Confirms dev state is consistent after migration |
| 4 | s3 | `prod` | Imports the GitHub OIDC provider into the prod workspace; provisions all prod infra |

The local-backend phase is required to create the S3 state bucket before it can be used as a backend. Both `dev` and `prod` environments share the same S3 bucket (`state-prod-default-project-name`) but store isolated state files under separate workspace paths (`env:/dev/…` and `env:/prod/…`).

### Teardown

```bash
./destroy.sh
```

Destroys all provisioned resources across both environments while preserving the GitHub OIDC provider in each workspace so the IAM trust relationship stays intact for future use. The script runs in three phases:

| Phase | Backend | Workspace | Action |
|---|---|---|---|
| 1 | s3 | `dev` | Destroys all dev infra except the OIDC provider and the shared S3 state bucket |
| 2 | s3 → local | `prod` | Migrates prod state to local so the S3 bucket is no longer the active backend |
| 3 | local | `prod` | Destroys all prod infra including the S3 state bucket (`force_destroy = true`) |

### Deploying a Change

Push to `main` — the CI/CD pipeline handles the rest:

```bash
git add .
git commit -m "update service"
git push origin main
```

GitHub Actions will build the Docker images, push them to ECR tagged with the commit SHA, register a new ECS task definition revision, and trigger a rolling deployment.

---

## AI Tools Used

**Claude Code** (Anthropic) was used throughout this assessment to assist with Terraform module structure, GitHub Actions workflow design, IAM policy scoping, and general AWS architecture guidance. All generated code was reviewed, tested, and adapted by the author.
