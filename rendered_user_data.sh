#!/bin/bash

# Function for logging
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Function to clean up any existing ECS agent containers
cleanup_ecs_containers() {
    log "Checking for existing ECS agent containers..."
    
    # Stop any running ecs-agent container
    if docker ps -q --filter name=ecs-agent | grep -q .; then
        log "Found running ECS agent container. Stopping it..."
        sudo docker stop ecs-agent || log "Warning: Failed to stop ECS agent container"
    fi
    
    # Remove any existing ecs-agent container (running or stopped)
    if docker ps -a -q --filter name=ecs-agent | grep -q .; then
        log "Found ECS agent container. Removing it..."
        sudo docker rm -f ecs-agent || log "Warning: Failed to remove ECS agent container"
    fi
    
    # Double check no containers are left
    if docker ps -a -q --filter name=ecs-agent | grep -q .; then
        log "Error: Failed to remove all ECS agent containers"
        return 1
    fi
    
    log "ECS agent container cleanup completed successfully"
    return 0
}

# Stop the services
log "Stopping ECS service"
sudo systemctl stop docker || log "Failed to stop docker service"
sudo systemctl stop ecs || log "Failed to stop ECS service"
sleep 5

# Update Docker
sudo yum update docker

# Start Docker
sudo systemctl start docker

# Clean up any existing ECS containers before proceeding
if ! cleanup_ecs_containers; then
    log "Error: Failed to clean up existing ECS containers. Exiting."
    exit 1
fi

#Create ECS config file
log "Creating ECS config"
sudo bash -c 'cat << EOF > /etc/ecs/ecs.config
ECS_CLUSTER=demo-cluster-d4db82ea
ECS_LOGLEVEL=debug
ECS_AVAILABLE_LOGGING_DRIVERS=["json-file","awslogs"]
ECS_ENABLE_CONTAINER_METADATA=true
ECS_ENGINE_TASK_CLEANUP_WAIT_DURATION=1h
ECS_IMAGE_CLEANUP_INTERVAL=10m
ECS_ENGINE_AUTH_TYPE=docker
ECS_ENGINE_AUTH_DATA={"https://index.docker.io/v1/": {"username": "sergyfxb@gmail.com", "password": "Wgi29022025!@#"}}
ECS_DATADIR=/data
ECS_ENABLE_SPOT_INSTANCE_DRAINING=true
ECS_CONTAINER_STOP_TIMEOUT=30s
ECS_CONTAINER_START_TIMEOUT=3m
EOF'

# Set proper permissions
log "Setting ECS config permissions"
sudo chmod 644 /etc/ecs/ecs.config

# Start ECS agent with platform specification
log "Starting ECS agent container"
sudo docker run --name ecs-agent \
    --detach=true \
    --restart=on-failure:10 \
    --volume=/var/run:/var/run \
    --volume=/var/log/ecs:/log \
    --volume=/var/lib/ecs/data:/data \
    --volume=/etc/ecs:/etc/ecs \
    --net=host \
    --env-file=/etc/ecs/ecs.config \
    --platform linux/amd64 \
    public.ecr.aws/ecs/amazon-ecs-agent:latest






