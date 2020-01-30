#!/bin/bash
#
# Creates ECS Fargate Cluster

# Check for all required variables
if [ "$SECURITY_GROUP" == '' ]; then
  echo "Please set a SECURITY_GROUP from your VPC (e.g. sg-12345678)"
  exit 2
fi
if [ "$VPC_ID" == '' ]; then
  echo "ECS requires using a VPC, so you must specify a VPC_ID"
  exit 3
fi
if [ "$CLUSTER" == '' ]; then
  echo "Please specify CLUSTER"
  exit 4
fi

# Check all optional variables
if [ "$SUBNET_ID" == '' ]; then
  SUBNET_ID=$(aws ec2 describe-subnets --filters Name=vpc-id,Values=$VPC_ID --query 'Subnets[*].[SubnetId]' --output text | tr '\n' ',')
fi

# Step 1 - Ensure we have the Role name 'ecsInstanceRole' created
# In most cases, the Amazon ECS instance role is automatically created for you in the console first-run experience.
ECS_ROLE_ID=$(aws iam get-role --role-name ecsInstanceRole --query 'Role.[RoleId]' --output text | tr -d '\n')
if [ "$ECS_ROLE_ID" == '' ]; then
  echo "You must create the 'ecsInstanceRole' as outlined by this article:"
  echo "http://docs.aws.amazon.com/AmazonECS/latest/developerguide/instance_IAM_role.html"
  exit 10
fi

# Step 2 - Ensure we have the Role name 'ecsCodeDeployRole' created
ECS_ROLE_ID=$(aws iam get-role --role-name ecsCodeDeployRole --query 'Role.[RoleId]' --output text | tr -d '\n')
if [ "$ECS_ROLE_ID" == '' ]; then
  echo "You must create the 'ecsCodeDeployRole' as outlined by this article:"
  echo "https://docs.aws.amazon.com/AmazonECS/latest/developerguide/codedeploy_IAM_role.html"
  exit 11
fi

# Step 3 - Create our ECS Fargate Cluster
echo "Detecting existing cluster/$CLUSTER"
CONTAINER_ARN=$(aws ecs describe-clusters --cluster $CLUSTER --query 'clusters[*].clusterArn' --output text)
if [ "$CONTAINER_ARN" != '' ]; then
  echo "Using existing cluster/$CLUSTER"
else
  echo "Creating cluster/$CLUSTER"
  # to create
  ecs-cli up --cluster $CLUSTER --launch-type FARGATE --capability-iam \
    --security-group $SECURITY_GROUP --vpc $VPC_ID --subnets $SUBNET_ID --force --verbose
fi

echo "Complete"
