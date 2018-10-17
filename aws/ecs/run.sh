# This script is built based on
# https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ECS_CLI_tutorial_fargate.html

# CONSTANT
TASK_EXECUTION_ROLE=ecsTaskExecutionRole
PROJECT_NAME=pocFlask
CLUSTER_NAME="$PROJECT_NAME"Cluster


########################################################
#  Step 1: Create the Task Execution IAM Role
########################################################

role_id=$(aws iam list-roles --query 'Roles[?RoleName==`'$TASK_EXECUTION_ROLE'`].RoleId')
if [ -z "$role_id" ]; then
    role_id=$(aws iam --region us-east-1 create-role \
        --role-name ecsTaskExecutionRole \
        --assume-role-policy-document file://task-execution-assume-role.json)
fi

# Assign task execution right and policy to this role
aws iam --region us-east-1 \
    attach-role-policy \
    --role-name $TASK_EXECUTION_ROLE \
    --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy

echo "The task execution role $TASK_EXECUTION_ROLE is created with id $role_id"


########################################################
# Step 2: Configure the ECS CLI
########################################################

ecs-cli configure \
    --cluster $CLUSTER_NAME \
    --region us-east-1 \
    --default-launch-type FARGATE \
    --config-name $CLUSTER_NAME

ecs-cli configure profile \
    --access-key $AWS_ACCESS_KEY_ID \
    --secret-key $AWS_SECRET_ACCESS_KEY \
    --profile-name $CLUSTER_NAME


########################################################
# Step 3: Create a Cluster
########################################################
ecs-cli configure default $CLUSTER_NAME --config-name $CLUSTER_NAME

cluster_status=$(aws ecs describe-clusters --cluster $CLUSTER_NAME | awk '{print $NF;}')
if [ $cluster_status == 'MISSING' ]; then
  ecs-cli up
fi

# Get cluster after created
cluster_status=$(aws ecs describe-clusters --cluster $CLUSTER_NAME | awk '{print $NF;}')

if [ $cluster_status != 'ACTIVE' ]; then
  echo ERROR: There is an error while creating the cluster: $CLUSTER_NAME
  exit 1
fi

echo "The cluster $CLUSTER_NAME is created."
