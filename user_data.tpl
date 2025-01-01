# #!/bin/bash

# # Redirect output to logs
# exec > >(tee /var/log/user-data.log)
# exec 2> >(tee /var/log/user-data.error.log >&2)

# # Function for logging
# log() {
#     echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
# }
# #
# log "Starting user data script execution"
# log "Testing log output"

# # Wait for cloud-init to complete
# cloud-init status --wait

# #install cli
# sudo yum install -y aws-cli

# # Define your variables first
# # Set and export variables
# export cluster_name="${cluster_name}"
# export log_group_name="${log_group_name}"
# export log_stream_name="${log_stream_name}"
# export region="${region}"


# # Write environment variables to /etc/environment
# echo "cluster_name=${cluster_name}" | sudo tee -a /etc/environment
# echo "log_group_name=${log_group_name}" | sudo tee -a /etc/environment
# echo "log_stream_name=${log_stream_name}" | sudo tee -a /etc/environment
# echo "region=${region}" | sudo tee -a /etc/environment

# # Create ECS config file
# log "Creating ECS config"
# sudo mkdir -p /etc/ecs
# sudo bash -c "cat << EOF > /etc/ecs/ecs.config
# ECS_CLUSTER=$CLUSTER_NAME
# ECS_LOGLEVEL=debug
# ECS_AVAILABLE_LOGGING_DRIVERS=[\"json-file\",\"awslogs\"]
# ECS_ENABLE_CONTAINER_METADATA=true
# ECS_ENGINE_TASK_CLEANUP_WAIT_DURATION=1h
# ECS_IMAGE_CLEANUP_INTERVAL=10m
# ECS_ENGINE_AUTH_TYPE=docker
# ECS_ENGINE_AUTH_DATA={\"https://index.docker.io/v1/\": {\"username\": \"$DOCKERHUB_USERNAME\", \"password\": \"$DOCKERHUB_PASSWORD\"}}
# ECS_DATADIR=/data
# ECS_ENABLE_SPOT_INSTANCE_DRAINING=true
# ECS_CONTAINER_STOP_TIMEOUT=30s
# ECS_CONTAINER_START_TIMEOUT=3m
# ECS_ENABLE_TASK_IAM_ROLE=true
# EOF"

# # Set proper permissions
# log "Setting ECS config permissions"
# sudo chmod 644 /etc/ecs/ecs.config

# # Stop the ECS service that starts automatically

# #Stop the services
# log "Stopping ECS service"

# sudo systemctl stop docker || log "Failed to stop docker service"
# sudo systemctl stop ecs || log "Failed to stop ECS service"
# sleep 10

# docker rm -f ecs-agent

# # Function to clean up any existing ECS agent containers
# cleanup_ecs_containers() {
#     log "Checking for existing ECS agent containers..."
#     if docker ps -q --filter name=ecs-agent | grep -q .; then
#         log "Found running ECS agent container. Stopping it..."
#         sudo docker stop ecs-agent || log "Warning: Failed to stop ECS agent container"
#     fi
#     if docker ps -a -q --filter name=ecs-agent | grep -q .; then
#         log "Found ECS agent container. Removing it..."
#         sudo docker rm -f ecs-agent || log "Warning: Failed to remove ECS agent container"
#     fi
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
# sudo yum update -y docker
# # Start Docker
# sudo systemctl start docker
# # Clean up existing ECS containers
# if ! cleanup_ecs_containers; then
#     log "Error: Failed to clean up existing ECS containers. Exiting."
#     exit 1
# fi


# # Restart services
# sudo systemctl restart docker

# sudo yum update -y ecs-init

# sudo systemctl restart ecs








