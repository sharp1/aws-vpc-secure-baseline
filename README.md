# AWS VPC Secure Baseline (Multi-AZ)

Beginner-friendly VPC design focused on **private-by-default networking**, tiered subnets, and controlled access patterns used in regulated environments.

## What this shows
- Clear VPC layout (public + private tiers across 2 AZs)
- Route table logic (public → IGW; private stays internal unless explicitly routed)
- Controlled access concept (management access without exposing private resources)

## Architecture
![VPC Diagram](docs/architecture/vpc-diagram.png)

Diagram source: `docs/architecture/vpc-drawing.excalidraw`

## Repo layout
- `docs/architecture/` diagrams + notes
- `docs/decisions/` short “why” docs (ADR-style)
- `iac/cloudformation/` CloudFormation templates
- `scripts/` helper scripts

## How to validate CloudFormation
```bash
aws cloudformation validate-template --template-body file://iac/cloudformation/vpc.yaml

