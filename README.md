# AWS VPC Secure Baseline (Multi-AZ)

A secure, private-by-default AWS VPC baseline built with CloudFormation.  
Designed to demonstrate **tiered subnet architecture, controlled administrative access, and least-privilege network paths** aligned with regulated / DoD-style environments.

---

## What this project demonstrates

- Multi-AZ VPC design with public, application, and data tiers
- Public vs private routing separation
- Bastion-based administrative access to private resources
- Security group–based trust boundaries between tiers
- Private resource isolation (no direct internet exposure)

---

## Architecture Overview

![VPC Diagram](docs/architecture/vpc-diagram.png)

Diagram source: `docs/architecture/vpc-drawing.excalidraw`

---

## Network Design

### VPC
- CIDR: `172.16.0.0/16`

### Subnets

| Tier | AZ | CIDR |
|------|----|------|
| PublicSubnet1A | AZ1 | 172.16.1.0/24 |
| PublicSubnet2B | AZ2 | 172.16.4.0/24 |
| AppPrivateSubnet1A | AZ1 | 172.16.2.0/24 |
| DataPrivateSubnet1A | AZ1 | 172.16.3.0/24 |
| AppPrivateSubnet2B | AZ2 | 172.16.5.0/24 |
| DataPrivateSubnet2B | AZ2 | 172.16.6.0/24 |

---

## Routing Model

**Public Subnets**
- Route: `0.0.0.0/0 → Internet Gateway`
- Used for: Bastion host / ingress tier

**Private Subnets**
- No internet route
- Use default VPC local routing only
- Used for: application tier + internal communication

> This enforces a **private-by-default posture** where internal systems are not internet reachable.

---
## Access Model (Network-level)

### Bastion Host (Public Subnet)
- SSH allowed only from your public IP (`/32`)
- Acts as controlled entry point into private tier

### AppInstance1A (Private)
- SSH allowed only from Bastion security group

### AppInstance2B (Private)
- No SSH access
- ICMP (ping) allowed only from AppInstance1A

This demonstrates:
- **Tier-to-tier trust relationships**
- **Identity of source via security groups**
- **Elimination of direct public access to private systems**

---

## Access Security Design

### Primary access: AWS Systems Manager (SSM Session Manager)
This baseline supports administrative access to instances using **AWS Systems Manager Session Manager**, avoiding inbound SSH as the default.

**How it works**
- Instances run the **amazon-ssm-agent**
- Instances assume an **IAM instance profile** with the AWS-managed policy **AmazonSSMManagedInstanceCore**
- Management traffic uses **HTTPS (TCP/443)**

### Private subnet support (no NAT required)
Private instances can reach Systems Manager using VPC endpoints (PrivateLink), keeping management traffic inside the VPC:

- **Interface endpoints** (PrivateLink) with **Private DNS enabled**
  - `com.amazonaws.${AWS::Region}.ssm`
  - `com.amazonaws.${AWS::Region}.ssmmessages`
  - `com.amazonaws.${AWS::Region}.ec2messages`
- **S3 gateway endpoint**
  - `com.amazonaws.${AWS::Region}.s3`

> **Note:** With Private DNS enabled on interface endpoints, AWS service hostnames resolve to endpoint ENI private IPs. The endpoint security group must allow **TCP/443** from any instance security group that should be managed via SSM (including the bastion if you want it managed via SSM).

### Optional / break-glass access: Bastion (Public Subnet)
For demonstration purposes, this baseline can also include a bastion host:
- SSH allowed only from your public IP (`/32`)
- Acts as a controlled entry point into the private tier if needed

---

This project demonstrates:
- Private subnet isolation (private-by-default routing)
- Least privilege network paths
- IAM-based administrative access using Systems Manager (Session Manager) instead of inbound SSH
- Private management-plane connectivity via VPC endpoints (PrivateLink) to avoid NAT for private subnets
- Endpoint security group controls to restrict management traffic to approved instance security groups
- East-West traffic control using security groups
- Multi-AZ tiered architecture design

---

## Deployment

### Prereqs
- AWS CLI configured (`aws configure`) and a profile with permissions to create VPC/IAM/EC2 resources

### Create the stack
```bash
aws cloudformation create-stack \
  --stack-name aws-vpc-secure-baseline \
  --template-body file://iac/cloudformation/vpc.yaml \
  --region us-east-1 \
  --profile <your-profile> \
  --capabilities CAPABILITY_NAMED_IAM

---

## Repo Layout
