#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Arrays to store found resources
declare -A found_resources

# Function to check if a resource exists
check_resource() {
    local resource_type=$1
    local command=$2
    
    echo -n "Checking for ${resource_type}... "
    # shellcheck disable=SC2155
    local resources=$(eval "$command")
    
    if [ -z "$resources" ]; then
        echo -e "${GREEN}None found${NC}"
    else
        echo -e "${RED}Resources found:${NC}"
        # shellcheck disable=SC2001
        echo "$resources" | sed 's/^/  /'
        found_resources[$resource_type]=$resources
    fi
}

# Main execution
echo "Checking for remaining AWS resources..."
echo "======================================="

check_resource "EC2 Instances" "aws ec2 describe-instances --filters Name=instance-state-name,Values=running,stopped,stopping --query 'Reservations[*].Instances[*].[InstanceId]' --output text"

check_resource "EBS Volumes" "aws ec2 describe-volumes --filters Name=status,Values=available,in-use --query 'Volumes[*].[VolumeId]' --output text"

check_resource "Elastic IP Addresses" "aws ec2 describe-addresses --query 'Addresses[*].[AllocationId]' --output text"

check_resource "Load Balancers" "aws elbv2 describe-load-balancers --query 'LoadBalancers[*].[LoadBalancerArn]' --output text"

check_resource "Auto Scaling Groups" "aws autoscaling describe-auto-scaling-groups --query 'AutoScalingGroups[*].[AutoScalingGroupName]' --output text"

check_resource "ECS Clusters" "aws ecs list-clusters --query 'clusterArns[]' --output text"

check_resource "ECS Services" "aws ecs list-clusters --query 'clusterArns[]' --output text | xargs -I {} aws ecs list-services --cluster {} --query 'serviceArns[]' --output text"

check_resource "RDS Instances" "aws rds describe-db-instances --query 'DBInstances[*].[DBInstanceIdentifier]' --output text"

check_resource "Lambda Functions" "aws lambda list-functions --query 'Functions[*].[FunctionName]' --output text"

check_resource "VPCs" "aws ec2 describe-vpcs --filters Name=isDefault,Values=false --query 'Vpcs[*].[VpcId]' --output text"

check_resource "Subnets" "aws ec2 describe-subnets --filters Name=default-for-az,Values=false --query 'Subnets[*].[SubnetId]' --output text"

check_resource "Internet Gateways" "aws ec2 describe-internet-gateways --query 'InternetGateways[*].[InternetGatewayId]' --output text"

check_resource "NAT Gateways" "aws ec2 describe-nat-gateways --filter Name=state,Values=available,pending --query 'NatGateways[*].[NatGatewayId]' --output text"

check_resource "Route Tables" "aws ec2 describe-route-tables --filters Name=association.main,Values=false --query 'RouteTables[*].[RouteTableId]' --output text"

check_resource "Security Groups" "aws ec2 describe-security-groups --filters Name=group-name,Values=!'default' --query 'SecurityGroups[*].[GroupId]' --output text"

check_resource "Network ACLs" "aws ec2 describe-network-acls --filters Name=default,Values=false --query 'NetworkAcls[*].[NetworkAclId]' --output text"

check_resource "VPC Peering Connections" "aws ec2 describe-vpc-peering-connections --query 'VpcPeeringConnections[*].[VpcPeeringConnectionId]' --output text"

check_resource "VPN Connections" "aws ec2 describe-vpn-connections --query 'VpnConnections[*].[VpnConnectionId]' --output text"

check_resource "VPN Gateways" "aws ec2 describe-vpn-gateways --query 'VpnGateways[*].[VpnGatewayId]' --output text"

check_resource "CloudWatch Log Groups" "aws logs describe-log-groups --query 'logGroups[*].[logGroupName]' --output text"

echo "======================================="
echo "Resource check completed."

# Menu for user action
if [ ${#found_resources[@]} -gt 0 ]; then
    echo -e "\n${YELLOW}Remaining resources found. Choose an action:${NC}"
    echo "1. Delete resources individually"
    echo "2. Skip deletion"
    echo "3. Delete all remaining resources"
    # shellcheck disable=SC2162
    read -p "Enter your choice (1-3): " choice

    case $choice in
        1)
            for resource_type in "${!found_resources[@]}"; do
                echo -e "\n${YELLOW}${resource_type}:${NC}"
                echo "${found_resources[$resource_type]}"
                # shellcheck disable=SC2162
                read -p "Delete these resources? (y/n): " delete_choice
                if [[ $delete_choice == "y" ]]; then
                    echo "Deleting ${resource_type}..."
                    # Add deletion logic here based on resource type
                fi
            done
            ;;
        2)
            echo "Skipping deletion. Resources left intact."
            ;;
        3)
            echo "Deleting all remaining resources..."
            for resource_type in "${!found_resources[@]}"; do
                echo "Deleting ${resource_type}..."
                # Add deletion logic here based on resource type
            done
            ;;
        *)
            echo "Invalid choice. Exiting without changes."
            ;;
    esac
else
    echo -e "\n${GREEN}All resources have been successfully deleted.${NC}"
fi
