#!/bin/bash

# Set error handling
set -eo pipefail

TERRAFORM_PATH=/Users/sagi/Desktop/terraform/git/ecs_auto_deployment-

# Setup logging
LOG_FILE="terraform_analysis_$(date +%Y%m%d_%H%M%S).log"

log() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $1" | tee -a "$LOG_FILE"
}

# Create directories for output
mkdir -p analysis_output

# Extract key resources and their relationships
extract_key_resources() {
    log "Extracting key infrastructure components..."
    
    # Extract VPC information
    terraform state list | grep "module.vpc" > analysis_output/vpc_resources.txt
    
    # Extract ECS related resources
    terraform state list | grep -E "module.ecs_(cluster|service|task)" > analysis_output/ecs_resources.txt
    
    # Extract ALB information
    terraform state list | grep "module.alb" > analysis_output/alb_resources.txt
    
    # Extract IAM roles and policies
    terraform state list | grep "module.ecs.*role" > analysis_output/iam_resources.txt
}

# Extract service dependencies
extract_dependencies() {
    log "Analyzing service dependencies..."
    
    # Create dependency map
    {
        echo "Service Dependencies:"
        echo "--------------------"
        echo "ECS Services depend on:"
        terraform state show module.ecs_service.aws_ecs_service.app | grep -E "cluster|task_definition|target_group" || true
        echo ""
        echo "Task Definitions depend on:"
        terraform state show module.ecs_task_definition.aws_ecs_task_definition.app | grep -E "role|execution_role" || true
    } > analysis_output/dependencies.txt
}

# Extract networking configuration
extract_network_config() {
    log "Extracting network configuration..."
    
    # Get VPC and subnet information
    {
        echo "Network Configuration:"
        echo "---------------------"
        terraform state list | grep -E "module.vpc.(aws_vpc|aws_subnet)" | while read -r resource; do
            echo "Resource: $resource"
            terraform state show "$resource" | grep -E "cidr_block|availability_zone" || true
            echo ""
        done
    } > analysis_output/network_config.txt
}

# Extract service configurations
extract_service_config() {
    log "Extracting service configurations..."
    
    # Get ECS service and task configurations
    {
        echo "Service Configurations:"
        echo "----------------------"
        terraform state list | grep -E "module.ecs_.*service" | while read -r resource; do
            echo "Service: $resource"
            terraform state show "$resource" | grep -E "desired_count|launch_type|platform_version" || true
            echo ""
        done
    } > analysis_output/service_config.txt
}

# Generate pipeline components based on analysis
generate_pipeline_components() {
    log "Generating pipeline components..."
    
    {
        echo "Pipeline Components:"
        echo "-------------------"
        
        # VPC deployment stage
        if [ -s analysis_output/vpc_resources.txt ]; then
            echo "1. VPC Deployment Stage Required"
        fi
        
        # ECS deployment stages
        if [ -s analysis_output/ecs_resources.txt ]; then
            echo "2. ECS Cluster Deployment Stage Required"
            echo "3. ECS Service Deployment Stage Required"
        fi
        
        # ALB deployment stage
        if [ -s analysis_output/alb_resources.txt ]; then
            echo "4. Load Balancer Deployment Stage Required"
        fi
        
        # IAM configuration stage
        if [ -s analysis_output/iam_resources.txt ]; then
            echo "5. IAM Configuration Stage Required"
        fi
    } > analysis_output/pipeline_components.txt
}

# Create pipeline variables list
generate_pipeline_variables() {
    log "Generating required pipeline variables..."
    
    {
        echo "Required Pipeline Variables:"
        echo "--------------------------"
        echo "AWS_ACCESS_KEY_ID"
        echo "AWS_SECRET_ACCESS_KEY"
        echo "AWS_REGION"
        echo "TF_VAR_environment"
        echo "TF_VAR_vpc_cidr"
        echo "TF_VAR_task_count"
        echo "TF_VAR_container_name"
        echo "TF_VAR_service_name"
        
        # Extract additional variables from state
        terraform show -json | jq -r '.values.root_module.resources[].values.tags // empty | keys[]' 2>/dev/null | sort -u | while read -r tag; do
            echo "TF_VAR_tag_$tag"
        done
    } > analysis_output/pipeline_variables.txt
}

# Main execution
main() {
    log "Starting Terraform state analysis..."
    
    # Run extraction functions
    extract_key_resources
    extract_dependencies
    extract_network_config
    extract_service_config
    generate_pipeline_components
    generate_pipeline_variables
    
    # Generate summary
    {
        echo "Analysis Summary:"
        echo "----------------"
        echo "1. Key Resources: $(wc -l < analysis_output/vpc_resources.txt) VPC resources"
        echo "2. ECS Resources: $(wc -l < analysis_output/ecs_resources.txt) ECS resources"
        echo "3. ALB Resources: $(wc -l < analysis_output/alb_resources.txt) ALB resources"
        echo "4. IAM Resources: $(wc -l < analysis_output/iam_resources.txt) IAM resources"
        echo ""
        echo "Pipeline components have been generated in analysis_output/pipeline_components.txt"
        echo "Required variables have been listed in analysis_output/pipeline_variables.txt"
    } > analysis_output/summary.txt
    
    log "Analysis complete. Check analysis_output directory for results."
}

# Execute main function
main