# ECS
A handy Elastic Container Services Toolkit in a Docker Image

## Functions
| Function | Action |
|----------|--------|
|create-cluster  | Create an ECS Cluster with EC2 instances|
|create-elb      | Create an Elastic Load Balancer for HTTPS|
|create-fargate  | Create a Fargate Cluster|
|create-roles    | Create required ECS Roles for the Parameter Store|
|destroy-cluster | Destroys a cluster - proceed with caution|
|down            | Perform a Dompose Down|
|get-login-password | Get ECR login password for username AWS|
|login           | Output a string to log into Elastic Container Registry (ECS)|
|ps              | List Containers running in the cluster|
|schedule-task   | Create an ECS Task that runs on a CRON schedule|
|up              | Perform a Compose Up|
|update          | Perform a Compose Down/Up|
|up-elb          | Perform a Compose Up using an ELB|
|update-elb      | Perform a Compose Down/Up using an ELB|

## Example
To deploy a docker-compose.yml file in the current working directory into an existing cluster, run:
```
docker run \
    -v $PWD:/deploy \
    --env CLUSTER=my-cluster \
    --env PROJECT_NAME=my-service-and-task-name \
    --env AWS_DEFAULT_REGION=us-west-1 \
    --env AWS_ACCESS_KEY_ID=ABCDEFG \
    --env AWS_SECRET_ACCESS_KEY=HIJKLMNOP \
    smithmicro/ecs:latest up
```

## Environment Variables
The following varaiables are used by the Docker image to perform various operations.

| Variable | Default | Function | Notes |
|---|---|---|---|
|AWS_DEFAULT_REGION||All|AWS Region (e.g. `us-east-1`)|
|AWS_ACCESS_KEY_ID||All|AWS Access Key|
|AWS_SECRET_ACCESS_KEY||All|AWS Secret Key|
|PROJECT_NAME||create-elb, schedule-task||
|CONTAINER_NAME||up-elb, update-elb||
|CERTIFICATE_ARN||create-elb||
|SECURITY_GROUP_HTTPS||create-elb|AWS Secuirty group that allows ports 443/tcp from amywhere|
|SECURITY_GROUP||create-cluster|AWS Secuirty group that allows ports 80/tcp from anywhere|
|KEY_NAME||create-cluster|AWS Security Key Pair .pem file (do not specify the .pem extension)|
|INSTANCE_TYPE|t3.small|create-cluster||
|VPC_ID||create-elb, create-cluster||
|CLUSTER||create-elb, create-cluster, schedule-task, up(any), down|Name that appears in ECS Console|
|COMPOSE|docker-compose.yml|schedule-task, up, update, up-elb, update-elb||
|TARGET_GROUP_ARN||up-elb, update-elb||
|CONTAINER_PORT||up-elb, update-elb|Port inside the Container to connect to ELB|
|SCHEDULE_HOUR|0|schedule-task|Hour (UTC) to run the job daily.  Use CRON_EXPRESSION if you want to customize further.|
|CRON_EXPRESSION|cron(0 0 * * ? *)|schedule-task|CRON Expression for ECS Task - Default: Daily at midnight UTC|

## Scheduling Tasks
In order to use the `schedule-task` feature, you will need to create the `ecsEventsRole` role.  Run the following command:
```
docker run \
    --env AWS_DEFAULT_REGION=$AWS_DEFAULT_REGION \
    --env AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID \
    --env AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY \
    smithmicro/ecs:latest create-roles
```

## SSM Parameter Store support
This image supports setting secrets in a ecs-param.yml file in the same format supported by ecs-cli.  There are only two steps:

1. Create the requried ecsTaskExecutionRole Role to support Parameter Store, ECR and CLoudWatch access.
```
docker run \
    --env AWS_DEFAULT_REGION=$AWS_DEFAULT_REGION \
    --env AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID \
    --env AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY \
    smithmicro/ecs:latest create-roles
```
2. Create a `ecs-parans.yml` file in the same directory as `docker-compose.yml`:
```
version: 1
task_definition:
  task_execution_role: ecsTaskExecutionRole
  services:
    paramstore-test:
      secrets:
        - value_from: NAME_OF_SECRET_IN_PARAMETER_STORE
          name: NAME_OF_SECRET_IN_CONTAINER
        - value_from: MY_APP_PGPASSWORD
          name: PGPASSWORD
```
The next time you run `update`, this file will be picked up and used automatically.

## ECR Login Example
You can use the ecs-cli command directly to issue log into AWS ECS, but if you don't want the dependencies of the ecs-cli, you can also this operation with smithmicro/ecs.

Example:
```
ECR_PASSWORD=$(docker run \
    --env AWS_DEFAULT_REGION=$AWS_DEFAULT_REGION \
    --env AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID \
    --env AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY \
    smithmicro/ecs:latest get-login-password)

ACCOUNT_ID=<your account>

echo -n $ECR_PASSWORD | docker login -u AWS --password-stdin https://$ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com

```
## Using AWS Assumed Role instead of normal IAM credentials
You can use the `aws sts assume-role` to utilize AWS assigned roles.  This allows for using centralized AWS account management and doesn't rely on AWS IAM accounts.

If your assigned cross account role is `arn:aws:iam::0123456789:role/AdminCrossAccount`, you can run the rollowing commands:
```
AWS_DATA=$(aws sts assume-role --role-arn arn:aws:iam::0123456789:role/AdminCrossAccount  --role-session-name=ecs-deployer | jq '.Credentials')
export AWS_ACCESS_KEY_ID=$(echo $AWS_DATA| jq -r '.AccessKeyId')
export AWS_SECRET_ACCESS_KEY=$(echo $AWS_DATA| jq -r '.SecretAccessKey')
export AWS_SESSION_TOKEN=$(echo $AWS_DATA| jq -r '.SessionToken')
```
You can then use the following sample docker commands.
```
docker run \
    --env AWS_DEFAULT_REGION=$AWS_DEFAULT_REGION \
    --env AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID \
    --env AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY \
    --env AWS_SESSION_TOKEN=$AWS_SESSION_TOKEN \
    smithmicro/ecs:latest create-cluster