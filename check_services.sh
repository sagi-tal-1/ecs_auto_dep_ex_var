#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Function to check if a resource exists
check_resource() {
    local resource_type=$1
    local command=$2
    
    echo -n "Checking for ${resource_type}... "
    local resources=$(eval "$command")
    
    if [ -z "$resources" ]; then
        echo -e "${GREEN}None found${NC}"
        return 1
    else
        echo -e "${RED}Resources found:${NC}"
        echo "$resources" | sed 's/^/  /'
        declare -g "${resource_type//-/_}=$resources"
        return 0
    fi
}

# Function to delete ECS Services
delete_ecs_services() {
    local cluster_name=$(echo $1 | cut -d'/' -f2)
    local service_name=$(echo $1 | cut -d'/' -f3)
    echo "Deleting ECS service: $service_name from cluster: $cluster_name"
    aws ecs update-service --cluster $cluster_name --service $service_name --desired-count 0
    sleep 30  # Wait for tasks to drain
    aws ecs delete-service --cluster $cluster_name --service $service_name --force
}

# Function to delete resources in order
delete_all_resources() {
    # 1. Scale down and delete ECS Services
    if [ ! -z "$ECS_Services" ]; then
        for service in $ECS_Services; do
            delete_ecs_services "$service"
        done
    fi
    sleep 30

    # 2. Delete Auto Scaling Groups
    if [ ! -z "$Auto_Scaling_Groups" ]; then
        for asg in $Auto_Scaling_Groups; do
            echo "Deleting Auto Scaling Group: $asg"
            aws autoscaling update-auto-scaling-group --auto-scaling-group-name $asg --min-size 0 --max-size 0 --desired-capacity 0
            sleep 30
            aws autoscaling delete-auto-scaling-group --auto-scaling-group-name $asg --force-delete
        done
    fi
    sleep 30

    # 3. Delete Load Balancers
    if [ ! -z "$Load_Balancers" ]; then
        for lb in $Load_Balancers; do
            echo "Deleting Load Balancer: $lb"
            aws elbv2 delete-load-balancer --load-balancer-arn $lb
        done
    fi
    sleep 30

    # 4. Delete Target Groups
    if [ ! -z "$Target_Groups" ]; then
        for tg in $Target_Groups; do
            echo "Deleting Target Group: $tg"
            aws elbv2 delete-target-group --target-group-arn $tg
        done
    fi

    # 5. Delete NAT Gateways
    if [ ! -z "$NAT_Gateways" ]; then
        for nat in $NAT_Gateways; do
            echo "Deleting NAT Gateway: $nat"
            aws ec2 delete-nat-gateway --nat-gateway-id $nat
        done
    fi
    sleep 30

    # 6. Release Elastic IPs
    if [ ! -z "$Elastic_IPs" ]; then
        for eip in $Elastic_IPs; do
            echo "Releasing Elastic IP: $eip"
            aws ec2 release-address --allocation-id $eip
        done
    fi

    # 7. Detach and Delete Internet Gateway
    if [ ! -z "$Internet_Gateways" ]; then
        for igw in $Internet_Gateways; do
            echo "Detaching and Deleting Internet Gateway: $igw"
            VPC_ID=$(aws ec2 describe-internet-gateways --internet-gateway-ids $igw --query 'InternetGateways[0].Attachments[0].VpcId' --output text)
            aws ec2 detach-internet-gateway --internet-gateway-id $igw --vpc-id $VPC_ID
            aws ec2 delete-internet-gateway --internet-gateway-id $igw
        done
    fi

    # 8. Delete Launch Templates
    if [ ! -z "$Launch_Templates" ]; then
        for lt in $Launch_Templates; do
            echo "Deleting Launch Template: $lt"
            aws ec2 delete-launch-template --launch-template-id $lt
        done
    fi

    # 9. Delete CloudWatch Log Groups
    if [ ! -z "$CloudWatch_Log_Groups" ]; then
        for log_group in $CloudWatch_Log_Groups; do
            echo "Deleting Log Group: $log_group"
            aws logs delete-log-group --log-group-name "$log_group"
        done
    fi

    # 10. Delete ECS Cluster
    if [ ! -z "$ECS_Clusters" ]; then
        for cluster in $ECS_Clusters; do
            echo "Deleting ECS Cluster: $cluster"
            aws ecs delete-cluster --cluster $cluster
        done
    fi

    # 11. Delete VPC (this will also delete associated subnets and security groups)
    if [ ! -z "$VPCs" ]; then
        for vpc in $VPCs; do
            echo "Deleting VPC: $vpc"
            aws ec2 delete-vpc --vpc-id $vpc
        done
    fi
}

# Main execution
echo "Checking for remaining AWS resources..."
echo "======================================="

check_resource "ECS_Clusters" "aws ecs list-clusters --query 'clusterArns[]' --output text"
check_resource "ECS_Services" "aws ecs list-clusters --query 'clusterArns[]' --output text | xargs -I {} aws ecs list-services --cluster {} --query 'serviceArns[]' --output text"
check_resource "Auto_Scaling_Groups" "aws autoscaling describe-auto-scaling-groups --query 'AutoScalingGroups[*].[AutoScalingGroupName]' --output text"
check_resource "Launch_Templates" "aws ec2 describe-launch-templates --query 'LaunchTemplates[*].[LaunchTemplateId]' --output text"
check_resource "Load_Balancers" "aws elbv2 describe-load-balancers --query 'LoadBalancers[*].[LoadBalancerArn]' --output text"
check_resource "Target_Groups" "aws elbv2 describe-target-groups --query 'TargetGroups[*].[TargetGroupArn]' --output text"
check_resource "NAT_Gateways" "aws ec2 describe-nat-gateways --filter Name=state,Values=available --query 'NatGateways[*].[NatGatewayId]' --output text"
check_resource "Elastic_IPs" "aws ec2 describe-addresses --query 'Addresses[*].[AllocationId]' --output text"
check_resource "Internet_Gateways" "aws ec2 describe-internet-gateways --query 'InternetGateways[*].[InternetGatewayId]' --output text"
check_resource "VPCs" "aws ec2 describe-vpcs --filters Name=isDefault,Values=false --query 'Vpcs[*].[VpcId]' --output text"
check_resource "CloudWatch_Log_Groups" "aws logs describe-log-groups --query 'logGroups[*].[logGroupName]' --output text"

echo "======================================="
echo "Resource check completed."

# Menu for user action
echo -e "\n${YELLOW}Choose an action:${NC}"
echo "1. Delete resources individually"
echo "2. Skip deletion"
echo "3. Delete all remaining resources"
read -p "Enter your choice (1-3): " choice

case $choice in
    1)
        echo "Individual deletion not implemented yet"
        ;;
    2)
        echo "Skipping deletion. Resources left intact."
        ;;
    3)
        echo "Deleting all resources..."
        delete_all_resources
        ;;
    *)
        echo "Invalid choice. Exiting without changes."
        ;;
esac