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
  echo "  create-elb      - Create an Elastic Load Balancer for HTTPS"
  echo "  create-cluster  - Create an ECS Cluster with ECS Instances"
  echo "  login           - Output a string to log into Elastic Container Registry (ECS)"
  echo "  schedule-task   - Create an ECS Task that runs on a CRON schedule"
  echo "  up              - Perform a Compose Up"
  echo "  update          - Perform a Compose Down then Up"
  echo "  up-elb          - Perform a Compose Up using an ELB"
  echo "  update-elb      - Perform a Compose Down then Up using an ELB"
  echo "  down            - Perform a Dompose Down"
  echo "  ps              - List Containers running in the cluster"
  exit 0
fi

if [ "$1" = 'login' ]; then
  requireRegion

  ECS_LOGIN=$(aws ecr get-login --region $AWS_DEFAULT_REGION --no-include-email)
  # remove the CR at the end of the string
  ECS_LOGIN="${ECS_LOGIN//[$'\r']}"
  echo -n $ECS_LOGIN
  exit 0
fi

if [ "$1" = 'create-cluster' ]; then
  requireCluster

  exec create-cluster.sh
fi

if [ "$1" = 'create-fargate' ]; then
  requireCluster

  exec create-fargate.sh
fi

if [ "$1" = 'create-elb' ]; then
  exec create-elb.sh
fi

if [ "$1" = 'schedule-task' ]; then
  requireCluster
  requireProjectName

  exec schedule-task.sh
fi

# Deploy
if [ "$1" = 'up' ]; then
  requireCluster
  requireProjectName

  # Start the service
  exec ecs-cli compose --file $COMPOSE --project-name $PROJECT_NAME service up --cluster $CLUSTER --create-log-groups
fi

# Re-eploy
if [ "$1" = 'update' ]; then
  requireCluster
  requireProjectName

  # Stop the service
  ecs-cli compose --file $COMPOSE --project-name $PROJECT_NAME service down --cluster $CLUSTER
  RETURN_VALUE=$?
  if [ $RETURN_VALUE -ne 0 ]; then
      echo "[ecs-cli compose service down] failed with error code: $RETURN_VALUE"
  fi

  echo "Waiting for the ECS Service to fully drain."
  while true; do
    SERVICE_STATUS=$(aws ecs describe-services --services $PROJECT_NAME --cluster $CLUSTER \
      --query 'services[*].status' --output text)
    echo "Service status is $SERVICE_STATUS"
    if [ "$SERVICE_STATUS" == "INACTIVE" ]; then
      break
    fi
    sleep 10
  done

  # Start the service
  exec ecs-cli compose --file $COMPOSE --project-name $PROJECT_NAME service up --cluster $CLUSTER --create-log-groups
fi

# Deploy with ELB
if [ "$1" = 'up-elb' ]; then
  requireCluster
  requireProjectName

  if [ "$TARGET_GROUP_ARN" == '' ]; then
    echo "Please set the TARGET_GROUP_ARN from your ELB"
    exit 11
  fi
  if [ "$CONTAINER_NAME" == '' ]; then
    echo "Please set veriable CONTAINER_NAME"
    exit 12
  fi
  # check all optional variables
  if [ "$CONTAINER_PORT" == '' ]; then
    CONTAINER_PORT=8080
  fi

  # Start the service
  exec ecs-cli compose --file $COMPOSE --project-name $PROJECT_NAME service up --cluster $CLUSTER --create-log-groups \
    --target-group-arn $TARGET_GROUP_ARN --container-name $CONTAINER_NAME --container-port $CONTAINER_PORT
fi

# Re-Deploy with ELB
if [ "$1" = 'update-elb' ]; then
  requireCluster
  requireProjectName

  if [ "$TARGET_GROUP_ARN" == '' ]; then
    echo "Please set the TARGET_GROUP_ARN from your ELB"
    exit 11
  fi
  if [ "$CONTAINER_NAME" == '' ]; then
    echo "Please set veriable CONTAINER_NAME"
    exit 12
  fi
  # check all optional variables
  if [ "$CONTAINER_PORT" == '' ]; then
    CONTAINER_PORT=8080
  fi

  # Stop the service
  ecs-cli compose --file $COMPOSE --project-name $PROJECT_NAME service down --cluster $CLUSTER
  RETURN_VALUE=$?
  if [ $RETURN_VALUE -ne 0 ]; then
      echo "[ecs-cli compose service down] failed with error code: $RETURN_VALUE"
  fi

  echo "Waiting for the ECS Service to fully drain."
  while true; do
    SERVICE_STATUS=$(aws ecs describe-services --services $PROJECT_NAME --cluster $CLUSTER \
      --query 'services[*].status' --output text)
    echo "Service status is $SERVICE_STATUS"
    if [ "$SERVICE_STATUS" == "INACTIVE" ]; then
      break
    fi
    sleep 10
  done

  # Start the service
  exec ecs-cli compose --file $COMPOSE --project-name $PROJECT_NAME service up --cluster $CLUSTER --create-log-groups \
    --target-group-arn $TARGET_GROUP_ARN --container-name $CONTAINER_NAME --container-port $CONTAINER_PORT
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

if [ "$1" = 'version' ]; then
  aws --version
  exec ecs-cli --version
fi


exec "$@"
