#!/bin/bash
#
# Creates an ECS Scheduled Task

# check for all required variables
if [ "$CLUSTER" == '' ]; then
  echo "Please specify CLUSTER"
  exit 1
fi
if [ "$PROJECT_NAME" == '' ]; then
  echo "Please set variable PROJECT_NAME"
  exit 2
fi

# Check all optional variables
if [ "$SCHEDULE_HOUR" == '' ]; then
  SCHEDULE_HOUR=0
fi
if [ "$CRON_EXPRESSION" == '' ]; then
  CRON_EXPRESSION="cron(0 $SCHEDULE_HOUR * * ? *)"
fi

echo "CRON Expression: $CRON_EXPRESSION"

# Step 1 - Ensure we have the Role name 'ecsEventsRole' created
ECS_ROLE_ARN=$(aws iam get-role --role-name ecsEventsRole --query 'Role.Arn' --output text)
if [ "$ECS_ROLE_ARN" == '' ]; then
  echo "You must create the 'ecsEventsRole' as outlined by the README.md."
  echo "See the section named 'Scheduling Tasks'"
  exit 1
fi

# Step 2 - Create or Update our Task Definition
ecs-cli compose --file $COMPOSE --project-name $PROJECT_NAME create --cluster $CLUSTER --create-log-groups
TASK_ARN=$(aws ecs describe-task-definition --task-definition $PROJECT_NAME --query 'taskDefinition.taskDefinitionArn' --output text)
echo "TaskDefinitionArn: $TASK_ARN"

# Step 3 - Create a Rule
RULE_NAME="${PROJECT_NAME}-rule"
RULE_ARN=$(aws events put-rule --schedule-expression "$CRON_EXPRESSION" --name $RULE_NAME --query 'RuleArn' --output text)
echo "RuleArn named $RULE_NAME: $RULE_ARN"

CLUSTER_ARN=$(aws ecs describe-clusters --cluster $CLUSTER --query 'clusters[*].clusterArn' --output text)
echo "ClusterArn: $CLUSTER_ARN"

# Step 4 - Create an Event
aws events put-targets --rule $RULE_NAME --targets "Id"="1","Arn"="$CLUSTER_ARN","RoleArn"="$ECS_ROLE_ARN","EcsParameters"="{"TaskDefinitionArn"= "$TASK_ARN","TaskCount"= 1}"

echo "Complete"
