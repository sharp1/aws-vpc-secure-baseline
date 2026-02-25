#!/usr/bin/env bash
set -euo pipefail

STACK_NAME="${1:-vpc-secure-baseline}"
REGION="${AWS_REGION:-us-east-1}"

aws cloudformation delete-stack --region "$REGION" --stack-name "$STACK_NAME"
echo "Delete initiated: $STACK_NAME"
#!/usr/bin/env bash
set -euo pipefail

STACK_NAME="${1:-vpc-secure-baseline}"
TEMPLATE="iac/cloudformation/vpc.yaml"
REGION="${AWS_REGION:-us-east-1}"

aws cloudformation validate-template \
  --region "$REGION" \
  --template-body "file://$TEMPLATE"

aws cloudformation deploy \
  --region "$REGION" \
  --stack-name "$STACK_NAME" \
  --template-file "$TEMPLATE"
