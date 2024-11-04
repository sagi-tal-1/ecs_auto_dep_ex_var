#!/bin/bash

# Enable debugging and logging
set -x
exec > >(tee /var/log/user-data.log | logger -t user-data -s 2>/dev/console) 2>&1

# Function for logging
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

log "Starting user data script execution"

sleep 5

# Function to wait for yum to be free
wait_for_yum() {
    while sudo fuser /var/run/yum.pid > /dev/null 2>&1; do
        log "Waiting for yum to be free..."
        sleep 5
    done
}

# Update system packages
log 'Updating system packages'
sudo yum update -y
wait


# Install AWS CLI
log "Installing AWS CLI"
sudo yum install -y aws-cli
wait

# Set and export variables
export CLUSTER_NAME="${cluster_name}"
export LOG_GROUP_NAME="${log_group_name}"
export LOG_STREAM_NAME="${log_stream_name}"
export REGION="${region}"


# Write environment variables to /etc/environment for persistence
echo "CLUSTER_NAME=${cluster_name}" | sudo tee -a /etc/environment
echo "LOG_GROUP_NAME=${log_group_name}" | sudo tee -a /etc/environment
echo "LOG_STREAM_NAME=${log_stream_name}" | sudo tee -a /etc/environment
echo "REGION=${region}" | sudo tee -a /etc/environment


# # Reload environment variables to make them available in the current session
source /etc/environment

# Write environment variables to /etc/environment and /etc/ecs/ecs.config directory
log "Setting up environment variables"
sudo mkdir -p /etc/ecs
sudo tee /etc/ecs/ecs.config > /dev/null <<EOF
ECS_CLUSTER=$CLUSTER_NAME
ECS_LOGLEVEL=debug
ECS_LOGFILE=/var/log/ecs/ecs-agent.log
ECS_AVAILABLE_LOGGING_DRIVERS=["json-file","awslogs"]
ECS_ENABLE_CONTAINER_METADATA=true
ECS_ENGINE_TASK_CLEANUP_WAIT_DURATION=1h
ECS_IMAGE_CLEANUP_INTERVAL=10m
ECS_ENGINE_AUTH_TYPE=docker

ECS_DATADIR=/data
ECS_ENABLE_SPOT_INSTANCE_DRAINING=true
ECS_CONTAINER_STOP_TIMEOUT=30s
ECS_CONTAINER_START_TIMEOUT=3m
ECS_ENABLE_TASK_IAM_ROLE=true
ECS_DOCKER_API_VERSION=1.24
ECS_CONTAINER_METADATA_URI_ENDPOINT=v4
EOF

docker stop ecs-agent

docker rm -f ecs-agent


# delete the ECS agent's state file to allow it to reinitialize with the correct configuration:
sudo rm /var/lib/ecs/data/agent.db

sudo systemctl restart ecs


# Additional verification steps
docker info || log "Docker not running properly"
curl -s http://localhost:51678/v1/metadata || log "ECS agent not responding"



# # Update the system and install the latest ECS agent
# yum update -y
# amazon-linux-extras install -y ecs
# yum install -y ecs-init

# # Configure ECS cluster
# echo "ECS_CLUSTER=MyCluster" >> /etc/ecs/ecs.config

# # Start ECS service
# systemctl enable --now ecs

# # Restart Docker to ensure it's running the latest version
# systemctl restart docker

# # Wait for Docker to be fully operational
# timeout=60
# while [ $timeout -gt 0 ]; do
#     if docker info &>/dev/null; then
#         break
#     fi
#     sleep 1
#     ((timeout--))
# done

# if [ $timeout -eq 0 ]; then
#     echo "Docker did not start within the expected time frame"
#     exit 1
# fi

# # Check the ECS agent version
# ecs_agent_version=$(docker inspect ecs-agent | grep Version | head -n 1)
# echo "ECS Agent Version: $ecs_agent_version"

# # Verify ECS agent is running
# if curl -s http://localhost:51678/v1/metadata &>/dev/null; then
#     echo "ECS agent is responding"
# else
#     echo "ECS agent is not responding"
# fi

# echo "User data script completed"


# # Write environment variables to /etc/environment and /etc/ecs/ecs.config directory
# log "Setting up environment variables"
# sudo mkdir -p /etc/ecs
# sudo tee /etc/ecs/ecs.config > /dev/null <<EOF
# ECS_CLUSTER=$CLUSTER_NAME
# ECS_LOGLEVEL=debug
# ECS_LOGFILE=/var/log/ecs/ecs-agent.log
# ECS_AVAILABLE_LOGGING_DRIVERS=["json-file","awslogs"]
# ECS_ENABLE_CONTAINER_METADATA=true
# ECS_ENGINE_TASK_CLEANUP_WAIT_DURATION=1h
# ECS_IMAGE_CLEANUP_INTERVAL=10m
# ECS_ENGINE_AUTH_TYPE=docker
# ECS_ENGINE_AUTH_DATA={"https://index.docker.io/v1/": {"username": "$DOCKERHUB_USERNAME", "password": "$DOCKERHUB_PASSWORD"}}
# ECS_DATADIR=/data
# ECS_ENABLE_SPOT_INSTANCE_DRAINING=true
# ECS_CONTAINER_STOP_TIMEOUT=30s
# ECS_CONTAINER_START_TIMEOUT=3m
# ECS_ENABLE_TASK_IAM_ROLE=true
# EOF

# # Set proper permissions
# log "Setting permissions on ECS config"
# sudo chmod 644 /etc/ecs/ecs.config

# # Create data directory
# log "Creating ECS data directory"
# sudo mkdir -p /data
# sudo chmod 744 /data

# # Clean up any existing ECS containers
# log "Cleaning up existing ECS containers"
# if command -v docker &> /dev/null; then
#     if docker ps -a --filter name=ecs-agent | grep -q .; then
#         docker rm -f $(docker ps -a --filter name=ecs-agent -q)
#     fi
# fi

# # Stop and disable the default ECS service if it exists
# log "Managing ECS services"
# if systemctl is-active ecs.service &> /dev/null; then
#     sudo systemctl stop ecs.service
#     sudo systemctl disable ecs.service
# fi

# # Update and start Docker
# log "Updating and starting Docker"
# sudo yum update -y docker
# sudo systemctl enable docker
# sudo systemctl start docker

# # Wait for Docker to be fully started
# log 'Waiting for Docker to start...'
# until sudo systemctl is-active --quiet docker; do
#     sleep 5
# done

# # Update ECS agent
# log "Updating ECS agent"
# sudo yum update -y ecs-init
# sudo systemctl stop ecs 
# docker rm -f ecs-agent
# rm -rf /var/lib/ecs/data/*
# sudo systemctl enable ecs
# sudo systemctl start ecs

# # Final verification
# log "Verifying ECS agent status"
# sleep 10
# sudo systemctl status ecs

# # Log completion
# log "User data script completed"

# # Additional verification steps
# docker info || log "Docker not running properly"
# curl -s http://localhost:51678/v1/metadata || log "ECS agent not responding"

























# # Function for logging
# log() {
#     echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
# }

# #install cli
# sudo yum install -y aws-cli


# # Function to clean up any existing ECS agent containers
# cleanup_ecs_containers() {
#     log "Checking for existing ECS agent containers..."
    
#     # Stop any running ecs-agent container
#     if docker ps -q --filter name=ecs-agent | grep -q .; then
#         log "Found running ECS agent container. Stopping it..."
#         sudo docker stop ecs-agent || log "Warning: Failed to stop ECS agent container"
#     fi
    
#     # Remove any existing ecs-agent container (running or stopped)
#     if docker ps -a -q --filter name=ecs-agent | grep -q .; then
#         log "Found ECS agent container. Removing it..."
#         sudo docker rm -f ecs-agent || log "Warning: Failed to remove ECS agent container"
#     fi
    
#     # Double check no containers are left
#     if docker ps -a -q --filter name=ecs-agent | grep -q .; then
#         log "Error: Failed to remove all ECS agent containers"
#         return 1
#     fi
    
#     log "ECS agent container cleanup completed successfully"
#     return 0
# }

# # Stop the services
# log "Stopping ECS service"
# sudo systemctl stop docker || log "Failed to stop docker service"
# sudo systemctl stop ecs || log "Failed to stop ECS service"
# sleep 5

# # Update Docker
# sudo yum update docker

# # Start Docker
# sudo systemctl start docker

# # Clean up any existing ECS containers before proceeding
# if ! cleanup_ecs_containers; then
#     log "Error: Failed to clean up existing ECS containers. Exiting."
#     exit 1
# fi

# #Create ECS config file
# log "Creating ECS config"
# sudo bash -c 'cat << EOF > /etc/ecs/ecs.config
# ECS_CLUSTER=${cluster_name}
# ECS_LOGLEVEL=debug
# ECS_AVAILABLE_LOGGING_DRIVERS=["json-file","awslogs"]
# ECS_ENABLE_CONTAINER_METADATA=true
# ECS_ENGINE_TASK_CLEANUP_WAIT_DURATION=1h
# ECS_IMAGE_CLEANUP_INTERVAL=10m
# ECS_ENGINE_AUTH_TYPE=docker

# ECS_DATADIR=/data
# ECS_ENABLE_SPOT_INSTANCE_DRAINING=true
# ECS_CONTAINER_STOP_TIMEOUT=30s
# ECS_CONTAINER_START_TIMEOUT=3m
# ECS_ENABLE_TASK_IAM_ROLE=true
# EOF'

# # Set proper permissions
# log "Setting ECS config permissions"
# sudo chmod 644 /etc/ecs/ecs.config


# #restart docker
# sudo systemctl restart docker


# #update ecs agent
# sudo yum update -y ecs-init

# #restart ecs agent
# sudo systemctl restart ecs


# Start ECS agent with platform specification
# sudo systemctl start ecs
# log "Starting ECS agent container"
# sudo docker run --name ecs-agent \
#     --detach=true \
#     --restart=on-failure:10 \
#     --volume=/var/run:/var/run \
#     --volume=/var/log/ecs:/log \
#     --volume=/var/lib/ecs/data:/data \
#     --volume=/etc/ecs:/etc/ecs \
#     --net=host \
#     --env-file=/etc/ecs/ecs.config \
#     --platform linux/amd64 \
#     public.ecr.aws/ecs/amazon-ecs-agent:latest






