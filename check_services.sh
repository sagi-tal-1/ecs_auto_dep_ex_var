#!/bin/bash

# Check for running EC2 instances
echo "Checking for running EC2 instances..."
aws ec2 describe-instances --query 'Reservations[*].Instances[*].[InstanceId, State.Name]' --output table

# Check for EBS volumes
echo -e "\nChecking for EBS volumes..."
aws ec2 describe-volumes --query 'Volumes[*].[VolumeId, State, Size, Attachments]' --output table

# Check for Elastic IP addresses
echo -e "\nChecking for Elastic IP addresses..."
aws ec2 describe-addresses --query 'Addresses[*].[PublicIp, InstanceId, AllocationId]' --output table

# Check for Load Balancers
echo -e "\nChecking for Elastic Load Balancers..."
aws elbv2 describe-load-balancers --output table

# Check for Auto Scaling Groups
echo -e "\nChecking for Auto Scaling Groups..."
aws autoscaling describe-auto-scaling-groups --output table

# Check for ECS Services (replace 'your-cluster-name' with your actual ECS cluster name)
ECS_CLUSTER_NAME="your-cluster-name"
echo -e "\nChecking for ECS Services in cluster: $ECS_CLUSTER_NAME..."
aws ecs list-services --cluster $ECS_CLUSTER_NAME --output table

# Check for RDS instances
echo -e "\nChecking for RDS instances..."
aws rds describe-db-instances --query 'DBInstances[*].[DBInstanceIdentifier, DBInstanceStatus]' --output table

# Check for Lambda functions
echo -e "\nChecking for Lambda functions..."
aws lambda list-functions --query 'Functions[*].[FunctionName, State]' --output table

