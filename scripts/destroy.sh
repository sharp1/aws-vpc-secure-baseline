#!/usr/bin/env bash
set -euo pipefail

STACK_NAME="${1:-vpc-secure-baseline}"
REGION="${AWS_REGION:-us-east-1}"

aws cloudformation delete-stack --region "$REGION" --stack-name "$STACK_NAME"
echo "Delete initiated: $STACK_NAME"
