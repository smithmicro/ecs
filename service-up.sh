#!/bin/bash
#

# optional variables
if [ "$COMPOSE" == '' ]; then
  COMPOSE=docker-compose.yml
fi

# check all required variables
if [ "$CLUSTER" == '' ]; then
  echo "Please set variable CLUSTER"
  exit 2
fi
if [ "$PROJECT_NAME" == '' ]; then
  echo "Please set variable PROJECT_NAME"
  exit 3
fi

# Deploy
if [ "$1" = 'up' ]; then
  # Start the service
  exec ecs-cli compose --file $COMPOSE --project-name $PROJECT_NAME service up --cluster $CLUSTER --create-log-groups
fi

# Re-Deploy
if [ "$1" = 'update' ]; then
  # Stop the service
  ecs-cli compose --file $COMPOSE --project-name $PROJECT_NAME service down --cluster $CLUSTER
  RETURN_VALUE=$?
  if [ $RETURN_VALUE -ne 0 ]; then
    echo "[ecs-cli compose service down] failed with error code: $RETURN_VALUE"
  else
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
  fi
  # Start the service
  exec ecs-cli compose --file $COMPOSE --project-name $PROJECT_NAME service up --cluster $CLUSTER --create-log-groups
fi

# Deploy with ELB
if [ "$1" = 'up-elb' ]; then
  if [ "$TARGET_GROUP_ARN" == '' ]; then
    echo "Please set the TARGET_GROUP_ARN from your ELB"
    exit 11
  fi
  if [ "$CONTAINER_NAME" == '' ]; then
    echo "Please set veriable CONTAINER_NAME"
    exit 12
  fi
  if [ "$CONTAINER_PORT" == '' ]; then
    echo "Please set veriable CONTAINER_PORT"
    exit 13
  fi

  # Start the service
  exec ecs-cli compose --file $COMPOSE --project-name $PROJECT_NAME service up --cluster $CLUSTER --create-log-groups \
    --target-group-arn $TARGET_GROUP_ARN --container-name $CONTAINER_NAME --container-port $CONTAINER_PORT
fi

# Re-Deploy with ELB
if [ "$1" = 'update-elb' ]; then
  if [ "$TARGET_GROUP_ARN" == '' ]; then
    echo "Please set the TARGET_GROUP_ARN from your ELB"
    exit 11
  fi
  if [ "$CONTAINER_NAME" == '' ]; then
    echo "Please set veriable CONTAINER_NAME"
    exit 12
  fi
  if [ "$CONTAINER_PORT" == '' ]; then
    echo "Please set veriable CONTAINER_PORT"
    exit 13
  fi

  # Stop the service
  ecs-cli compose --file $COMPOSE --project-name $PROJECT_NAME service down --cluster $CLUSTER
  RETURN_VALUE=$?
  if [ $RETURN_VALUE -ne 0 ]; then
    echo "[ecs-cli compose service down] failed with error code: $RETURN_VALUE"
  else
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
  fi

  # Start the service
  exec ecs-cli compose --file $COMPOSE --project-name $PROJECT_NAME service up --cluster $CLUSTER --create-log-groups \
    --target-group-arn $TARGET_GROUP_ARN --container-name $CONTAINER_NAME --container-port $CONTAINER_PORT
fi
