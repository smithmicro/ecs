#!/bin/bash
#
# Create an Elastic Load Balancer

# Create an IPv4 VPC and Subnets Using the AWS CLI
# http://docs.aws.amazon.com/AmazonVPC/latest/UserGuide/vpc-subnets-commands-example.html

if [ "$SECURITY_GROUP_HTTPS" == '' ]; then
  echo "Please set a SECURITY_GROUP_HTTPS that allows ports 443/tcp from all sources (e.g. sg-12345678)"
  exit 1
fi
if [ "$VPC_ID" == '' ]; then
  echo "ELB requires using a VPC, so you must specify a VPC_ID"
  exit 2
fi
if [ "$CERTIFICATE_ARN" == '' ]; then
  echo "CERTIFICATE_ARN not specified.  This is required to create an HTTPS LB."
  exit 3
fi
if [ "$PROJECT_NAME" == '' ]; then
  echo "Please set variable PROJECT_NAME"
  exit 4
fi

# Keep the tags consistant so we can easily detect if a VPC already exists
ELB_TAGS="Key=Name,Value=$PROJECT_NAME Key=Owner,Value=$PROJECT_NAME"

# Get our subnets from the VPC
SUBNET_ID=$(aws ec2 describe-subnets --filters Name=vpc-id,Values=$VPC_ID --query 'Subnets[*].[SubnetId]' --output text | tr '\n' ' ')

# Step 1 - Create a Load Balancer
ELB_ARN=$(aws elbv2 create-load-balancer --name $PROJECT_NAME \
  --query 'LoadBalancers[*].LoadBalancerArn' \
  --subnets $SUBNET_ID --security-groups $SECURITY_GROUP_HTTPS --tags $ELB_TAGS \
  --output text | tr -d '\n')

echo "Created ELB ARN: $ELB_ARN"

# Step 2 - Create a Target Group
TARGET_GROUP_ARN=$(aws elbv2 create-target-group --name $PROJECT_NAME \
  --protocol HTTP --port 80 --vpc-id $VPC_ID \
  --query 'TargetGroups[*].TargetGroupArn' --output text | tr -d '\n')

echo "Created Target Group ARN: $TARGET_GROUP_ARN"

# Step 2 - Create a Listener
if [ "$CERTIFICATE_ARN" == '' ]; then
  LISTENER_ARN=$(aws elbv2 create-listener --load-balancer-arn $ELB_ARN --protocol HTTP --port 80 \
    --default-actions Type=forward,TargetGroupArn=$TARGET_GROUP_ARN \
    --query 'Listeners[*].ListenerArn' --output text | tr -d '\n')
else
  LISTENER_ARN=$(aws elbv2 create-listener --load-balancer-arn $ELB_ARN --protocol HTTPS --port 443 \
    --default-actions Type=forward,TargetGroupArn=$TARGET_GROUP_ARN \
    --certificates CertificateArn=$CERTIFICATE_ARN \
    --query 'Listeners[*].ListenerArn' --output text | tr -d '\n')
fi

echo "Created Listener ARN: $LISTENER_ARN"

ELB_ENDPOINT=$(aws elbv2 describe-load-balancers --load-balancer-arns $ELB_ARN \
  --query 'LoadBalancers[*].DNSName' \
  --output text | tr -d '\n')

echo "ELB Endpoint: $ELB_ENDPOINT"

export ELB_ENDPOINT

echo ""
echo "For your Cluster Up command (up-elb):"
echo "--env TARGET_GROUP_ARN=$TARGET_GROUP_ARN"
echo ""

echo "Complete"
