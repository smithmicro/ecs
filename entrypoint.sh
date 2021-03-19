#!/bin/bash
#

# optional variables

if [ "$COMPOSE" == '' ]; then
  COMPOSE=docker-compose.yml
fi

function requireRegion()
{
  # check all required variables
  if [ "$AWS_DEFAULT_REGION" == '' ]; then
    echo "Please set variable AWS_DEFAULT_REGION"
    exit 1
  fi
}

function requireCluster() 
{
  # check all required variables
  if [ "$CLUSTER" == '' ]; then
    echo "Please set variable CLUSTER"
    exit 2
  fi
}

function requireProjectName()
{
  # check all required variables
  if [ "$PROJECT_NAME" == '' ]; then
    echo "Please set variable PROJECT_NAME"
    exit 3
  fi
}

# Deploy
if [ "$1" = 'help' ]; then
  echo "Commands:"
  echo "  create-cluster     - Create an ECS Cluster with ECS Instances"
  echo "  create-elb         - Create an Elastic Load Balancer for HTTPS"
  echo "  create-fargate     - Create a Fargate Cluster"
  echo "  create-roles       - Create required ECS Roles for the Parameter Store"
  echo "  destroy-cluster    - Destroys a cluster - proceed with caution"
  echo "  down               - Perform a Dompose Down"
  echo "  get-login-password - Get ECR login password for username AWS"
  echo "  login              - Output a string to log into Elastic Container Registry (ECS)"
  echo "  ps                 - List Containers running in the cluster"
  echo "  schedule-task      - Create an ECS Task that runs on a CRON schedule"
  echo "  up                 - Perform a Compose Up"
  echo "  update             - Perform a Compose Down then Up"
  echo "  up-elb             - Perform a Compose Up using an ELB"
  echo "  update-elb         - Perform a Compose Down then Up using an ELB"
  exit 0
fi

if [ "$1" = 'login' ]; then
  requireRegion

  ECS_LOGIN=$(aws ecr get-login-password --region $AWS_DEFAULT_REGION)
  # remove the CR at the end of the string
  ECS_LOGIN="${ECS_LOGIN//[$'\r']}"

  ACCOUNT_ID=$(aws ecr describe-registry --query 'registryId' --output text)
  ECR="$ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com"

  echo -n "docker login -u AWS -p $ECS_LOGIN https://$ECR"
  exit 0
fi

if [ "$1" = 'get-login-password' ]; then
  requireRegion

  exec aws ecr get-login-password --region $AWS_DEFAULT_REGION
fi

if [ "$1" = 'create-cluster' ]; then
  exec create-cluster.sh
fi

if [ "$1" = 'create-fargate' ]; then
  exec create-fargate.sh
fi

if [ "$1" = 'create-elb' ]; then
  exec create-elb.sh
fi

if [ "$1" = 'destroy-cluster' ]; then
  requireCluster
  requireRegion

  exec ecs-cli down --cluster $CLUSTER --region $AWS_DEFAULT_REGION --force
fi

if [ "$1" = 'schedule-task' ]; then
  exec schedule-task.sh
fi

# Deploy
if [ "$1" = 'up' ]; then
  exec service-up.sh $1
fi

if [ "$1" = 'update' ]; then
  exec service-up.sh $1
fi

# Deploy with ELB
if [ "$1" = 'up-elb' ]; then
  exec service-up.sh $1
fi

if [ "$1" = 'update-elb' ]; then
  exec service-up.sh $1
fi

if [ "$1" = 'ps' ]; then
  requireCluster
  exec ecs-cli ps --cluster $CLUSTER
fi

if [ "$1" = 'down' ]; then
  requireCluster
  requireProjectName

  # Service down
  exec ecs-cli compose --file $COMPOSE --project-name $PROJECT_NAME service down --cluster $CLUSTER
fi

if [ "$1" = 'create-roles' ]; then
  aws cloudformation create-stack --stack-name "ecsRoles" \
    --template-body file://$ECS_CONFIG_DIR/ecs-roles-cf.json \
    --capabilities CAPABILITY_NAMED_IAM
  echo "Waiting for CloudFormation Create Stack to complete..."
  aws cloudformation wait stack-create-complete --stack-name "ecsRoles"
  echo "Complete"
  exit 0
fi

if [ "$1" = 'version' ]; then
  aws --version
  exec ecs-cli --version
fi

exec "$@"
