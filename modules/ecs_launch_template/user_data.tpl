#!/bin/bash 

# Set and export variables
export cluster_name="${cluster_name}"
export log_group_name="${log_group_name}"
export log_stream_name="${log_stream_name}"
export region="${region}"
export dockerhub_username="${dockerhub_username}"
export dockerhub_password="${dockerhub_password}"

# Define log files with a fallback to user home directory if needed
LOG_FILE="/var/log/user-data.log"
ERROR_LOG="/var/log/user-data.error.log"

# Verify /var/log directory permissions, fallback if needed
if ! touch ${LOG_FILE} 2>/dev/null; then
    LOG_FILE="/home/ec2-user/user-data.log"
    ERROR_LOG="/home/ec2-user/user-data.error.log"
fi

# Function to log messages with timestamps
log() {
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $1" | tee -a "${LOG_FILE}" >&3
}

error_log() {
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] ERROR: $1" | tee -a "${ERROR_LOG}" >&4
}

# Set up error handling
exec 3>&1 # Save stdout to file descriptor 3
exec 4>&2 # Save stderr to file descriptor 4
set -e
trap 'error_log "Script failed on line $LINENO"' ERR

# Confirm variable export
log "Cluster Name: ${cluster_name}"
log "Log Group Name: ${log_group_name}"
log "Log Stream Name: ${log_stream_name}"
log "Region: ${region}"

# Validate Docker Hub credentials
if [ -z "${dockerhub_username}" ] || [ -z "${dockerhub_password}" ]; then
    error_log "Docker Hub credentials not provided"
    exit 1
fi

# Confirm ECS Cluster
if [ -z "${cluster_name}" ]; then
    error_log "ECS cluster name not provided"
    exit 1
fi

# Confirm CloudWatch Logs configuration
if [ -z "${log_group_name}" ] || [ -z "${log_stream_name}" ] || [ -z "${region}" ]; then
    error_log "CloudWatch Logs configuration incomplete"
    exit 1
fi

# Execute initial system updates and package installation
log "Updating and installing required packages..."
yum update -y
yum install -y awslogs jq aws-cli

# CloudWatch and ECS Agent Configuration
log "Configuring CloudWatch Logs and ECS Agent..."
mkdir -p /etc/awslogs /etc/ecs

# Create the awslogs.conf and awscli.conf for CloudWatch
cat > /etc/awslogs/awslogs.conf << EOF
[general]
state_file = /var/lib/awslogs/agent-state

[/var/log/ecs/ecs-agent.log]
file = /var/log/ecs/ecs-agent.log
log_group_name = ${log_group_name}
log_stream_name = ${log_stream_name}
datetime_format = %Y-%m-%d %H:%M:%S
EOF

cat > /etc/awslogs/awscli.conf << EOF
[plugins]
cwlogs = cwlogs
[default]
region = ${region}
EOF

# Configure ECS Agent
cat > /etc/ecs/ecs.config << EOF
ECS_CLUSTER=${cluster_name}
ECS_AVAILABLE_LOGGING_DRIVERS=["awslogs","json-file"]
EOF

# Docker Credential Configuration
log "Configuring Docker credentials..."
mkdir -p /root/.docker
auth_string=$(echo -n "${dockerhub_username}:${dockerhub_password}" | base64)

cat > /root/.docker/config.json << EOF
{
  "auths": {
    "https://index.docker.io/v1/": {
      "auth": "$auth_string"
    }
  }
}
EOF

chmod 600 /root/.docker/config.json
log "Docker configuration complete."

log "END: UserData Script Execution Completed Successfully"
