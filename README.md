# ECS
A handy Elastic Container Services Toolkit in a Docker Image

## Functions
| Function | Action |
|---|---|
|create-elb      | Create an Elastic Load Balancer for HTTPS|
|create-cluster  | Create an ECS Cluster with EC2 instances|
|create-fargate  | Create a Fargate Cluster|
|login           | Output a string to log into Elastic Container Registry (ECS)|
|schedule-task   | Create an ECS Task that runs on a CRON schedule|
|up              | Perform a Compose Up|
|update          | Perform a Compose Down/Up|
|up-elb          | Perform a Compose Up using an ELB|
|update-elb      | Perform a Compose Down/Up using an ELB|
|down            | Perform a Dompose Down|
|ps              | List Containers running in the cluster|

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
|CONTAINER_PORT|8080|up-elb, update-elb|Port inside the Container to connect to ELB|
|SCHEDULE_HOUR|0|schedule-task|Hour (UTC) to run the job daily.  Use CRON_EXPRESSION if you want to customize further.|
|CRON_EXPRESSION|cron(0 0 * * ? *)|schedule-task|CRON Expression for ECS Task - Default: Daily at midnight UTC|

## Future Development
CodeDeploy and Blue/Green deployments are under development.

### CodeDeploy Roles
You must follow these directions to support CodeDeploy.
This feature is in development
https://docs.aws.amazon.com/AmazonECS/latest/developerguide/codedeploy_IAM_role.html
