#!/bin/bash
dnf install nano -y
# Redirect all output to a log file and console
exec > >(tee /var/log/user-data.log | logger -t user-data -s 2>/dev/console) 2>&1

echo "Starting ECS setup script at $(date)"

# Set up ECS config
echo "Configuring ECS..."
mkdir -p /etc/ecs
cat << EOF > /etc/ecs/ecs.config
ECS_CLUSTER=${cluster_name}
ECS_ENABLE_CONTAINER_METADATA=true
EOF

# Ensure Docker is running
systemctl enable docker
systemctl start docker

# Stop ECS service if it's running
systemctl stop ecs

# Remove existing ECS agent container if it exists
docker rm -f ecs-agent || true

# Start ECS agent manually
echo "Starting ECS agent..."
docker run --name ecs-agent \
    --detach=true \
    --restart=on-failure:10 \
    --volume=/var/run:/var/run \
    --volume=/var/log/ecs/:/log \
    --volume=/var/lib/ecs/data:/data \
    --volume=/etc/ecs:/etc/ecs \
    --net=host \
    --env-file=/etc/ecs/ecs.config \
    amazon/amazon-ecs-agent:latest

# Wait for ECS agent to start
sleep 30

# Check if ECS agent container is running
if docker ps | grep -q ecs-agent; then
    echo "SUCCESS: ECS agent container is running"
else
    echo "ERROR: ECS agent container failed to start"
    docker logs ecs-agent
    exit 1
fi

echo "ECS setup script completed at $(date)"


# #!/bin/bash
# dnf install nano -y
# # Redirect all output to a log file and console
# exec > >(tee /var/log/user-data.log | logger -t user-data -s 2>/dev/console) 2>&1

# echo "Starting enhanced user-data script at $(date)"

# # Function to check last command status and log
# check_status() {
#     local status=$?
#     if [ $status -ne 0 ]; then
#         echo "ERROR: $1 failed"
#         return 1
#     else
#         echo "SUCCESS: $1 completed successfully"
#         return 0
#     fi
# }

# # Function to check if a service is running
# check_service() {
#     if systemctl is-active --quiet "$1"; then
#         echo "SUCCESS: $1 is running"
#         return 0
#     else
#         echo "ERROR: $1 is not running"
#         systemctl status "$1"
#         return 1
#     fi
# }

# # Function to check if a file exists
# check_file() {
#     if [ -f "$1" ]; then
#         echo "SUCCESS: File $1 exists"
#         return 0
#     else
#         echo "ERROR: File $1 does not exist"
#         return 1
#     fi
# }

# # Function to check if a string is in a file
# check_string_in_file() {
#     if grep -q "$1" "$2"; then
#         echo "SUCCESS: String '$1' found in $2"
#         return 0
#     else
#         echo "ERROR: String '$1' not found in $2"
#         return 1
#     fi
# }

# # Function to check IAM role permissions
# check_iam_permission() {
#     if aws "$1" "$2" "$3" "$4" 2>&1 | grep -q "An error occurred"; then
#         echo "ERROR: IAM role does not have permission to perform $1 $2"
#         return 1
#     else
#         echo "SUCCESS: IAM role has permission to perform $1 $2"
#         return 0
#     fi
# }

# # Ensure the script is running on an ECS-optimized AMI
# if ! grep -q "Amazon Linux 2" /etc/os-release; then
#     echo "ERROR: This script is intended to run on an ECS-optimized Amazon Linux 2 AMI"
#     exit 1
# fi

# # Install necessary tools (if not already present)
# echo "Ensuring necessary tools are installed..."
# yum install -y jq aws-cli
# check_status "Tool installation"

# # Check IAM role permissions
# echo "Checking IAM role permissions..."
# region=$(curl -s http://169.254.169.254/latest/meta-data/placement/region)
# check_iam_permission "ecs" "list-clusters" "--region" "$region"
# check_iam_permission "logs" "describe-log-groups" "--region" "$region"
# check_iam_permission "ec2" "describe-instances" "--region" "$region"

# # Set up ECS config
# echo "Configuring ECS..."
# mkdir -p /etc/ecs
# cat << EOF > /etc/ecs/ecs.config
# ECS_CLUSTER=${cluster_name}
# ECS_AVAILABLE_LOGGING_DRIVERS=["awslogs", "json-file"]
# ECS_ENABLE_CONTAINER_METADATA=true
# ECS_ENGINE_TASK_CLEANUP_WAIT_DURATION=1h
# ECS_IMAGE_PULL_BEHAVIOR=once
# ECS_ENABLE_SPOT_INSTANCE_DRAINING=true
# EOF
# check_status "ECS configuration"
# check_file "/etc/ecs/ecs.config"
# check_string_in_file "ECS_CLUSTER=${cluster_name}" "/etc/ecs/ecs.config"

# # Configure and start ECS agent
# echo "Ensuring ECS agent is configured and running..."
# systemctl enable --now ecs
# systemctl restart ecs
# check_service "ecs"

# # Wait for ECS agent to fully start
# sleep 30

# # Configure and start Docker (if not already running)
# echo "Ensuring Docker is configured and running..."
# if ! systemctl is-active --quiet docker; then
#     systemctl enable docker
#     systemctl start docker
# fi
# check_service "docker"

# # Set up Docker log rotation
# echo "Configuring Docker log rotation..."
# cat > /etc/docker/daemon.json <<EOF
# {
#   "log-driver": "json-file",
#   "log-opts": {
#     "max-size": "10m",
#     "max-file": "5"
#   }
# }
# EOF
# systemctl restart docker
# check_status "Docker log rotation configuration"
# check_file "/etc/docker/daemon.json"

# # Configure CloudWatch agent
# echo "Configuring CloudWatch agent..."
# cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << EOF
# {
#   "agent": {
#     "run_as_user": "root"
#   },
#   "logs": {
#     "logs_collected": {
#       "files": {
#         "collect_list": [
#           {
#             "file_path": "/var/log/messages",
#             "log_group_name": "${log_group_name}",
#             "log_stream_name": "{instance_id}/system-logs"
#           },
#           {
#             "file_path": "/var/log/ecs/ecs-init.log",
#             "log_group_name": "${log_group_name}",
#             "log_stream_name": "{instance_id}/ecs-init"
#           },
#           {
#             "file_path": "/var/log/ecs/ecs-agent.log",
#             "log_group_name": "${log_group_name}",
#             "log_stream_name": "{instance_id}/ecs-agent"
#           },
#           {
#             "file_path": "/var/log/user-data.log",
#             "log_group_name": "${log_group_name}",
#             "log_stream_name": "{instance_id}/user-data"
#           }
#         ]
#       }
#     }
#   },
#   "metrics": {
#     "metrics_collected": {
#       "cpu": {
#         "measurement": [
#           "usage_active",
#           "usage_system",
#           "usage_user"
#         ],
#         "metrics_collection_interval": 60
#       },
#       "memory": {
#         "measurement": [
#           "used_percent",
#           "used",
#           "total"
#         ],
#         "metrics_collection_interval": 60
#       },
#       "swap": {
#         "measurement": [
#           "used_percent",
#           "used",
#           "free"
#         ],
#         "metrics_collection_interval": 60
#       },
#       "disk": {
#         "measurement": [
#           "used_percent",
#           "used",
#           "total"
#         ],
#         "metrics_collection_interval": 60,
#         "resources": [
#           "/"
#         ]
#       }
#     }
#   }
# }
# EOF
# check_status "CloudWatch agent configuration"
# check_file "/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json"

# # Start CloudWatch agent
# echo "Starting CloudWatch agent..."
# /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
# systemctl enable amazon-cloudwatch-agent
# systemctl start amazon-cloudwatch-agent
# check_service "amazon-cloudwatch-agent"

# # Verify network connectivity
# echo "Verifying network connectivity..."
# if ping -c 3 amazon.com &> /dev/null; then
#     echo "SUCCESS: Network is reachable"
# else
#     echo "ERROR: Network is not reachable"
#     exit 1
# fi

# # Check ECS agent connectivity
# echo "Checking ECS agent connectivity..."
# if timeout 120s bash -c 'until curl -s http://localhost:51678/v1/metadata; do sleep 5; done' &> /dev/null; then
#     echo "SUCCESS: ECS agent is responsive"
# else
#     echo "ERROR: ECS agent is not responsive"
#     systemctl status ecs
#     journalctl -u ecs
#     exit 1
# fi

# # Verify Docker is operational
# echo "Verifying Docker functionality..."
# if docker run --rm hello-world &> /dev/null; then
#     echo "SUCCESS: Docker is operational"
# else
#     echo "ERROR: Docker is not functioning properly"
#     exit 1
# fi

# # Check if instance is registered with ECS cluster
# echo "Checking ECS cluster registration..."
# instance_id=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
# cluster_check=$(aws ecs list-container-instances --cluster "${cluster_name}" --filter "ec2InstanceId==$instance_id" --region "$region")
# if [[ $(echo "$cluster_check" | jq '.containerInstanceArns | length') -gt 0 ]]; then
#     echo "SUCCESS: Instance is registered with ECS cluster ${cluster_name}"
# else
#     echo "ERROR: Instance is not registered with ECS cluster ${cluster_name}"
#     exit 1
# fi

# # Final check for ECS agent
# if ! systemctl is-active --quiet ecs; then
#     echo "ERROR: ECS agent is not running at the end of the script"
#     systemctl status ecs
#     journalctl -u ecs
#     exit 1
# fi

# echo "All checks completed. User-data script finished at $(date)"

# # Final status check
# final_status=0
# for service in ecs docker amazon-cloudwatch-agent; do
#     if ! systemctl is-active --quiet "$service"; then
#         echo "ERROR: $service is not running"
#         final_status=1
#     fi
# done

# if [ $final_status -eq 0 ]; then
#     echo "SUCCESS: User-data script executed successfully"
# else
#     echo "ERROR: User-data script encountered issues"
#     exit 1
# fi