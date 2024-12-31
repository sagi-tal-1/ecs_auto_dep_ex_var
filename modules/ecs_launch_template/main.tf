
#moduls/ecs_launch_template/main.tf
data "aws_region" "current" {}

resource "aws_cloudwatch_log_group" "user_data_logs" {
  name              = "/var/log/user-data-logs"
  retention_in_days = 1
}


resource "aws_launch_template" "ecs_ec2" {
  name                = "launch_template"
  image_id      = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name

  network_interfaces {
    subnet_id                   = var.private_subnet_ids[0] #private #public
    associate_public_ip_address = false
    security_groups            =  [var.security_group_id]
  }

  iam_instance_profile {
    arn = var.iam_instance_profile_arn
  }


user_data = base64encode(<<-EOT
#!/bin/bash
set -e

LOGFILE="/var/log/ssm-setup.log"
touch $LOGFILE

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a $LOGFILE
}

# Wait for system initialization
sleep 15

# Configure ECS Agent
cat > /etc/ecs/ecs.config << 'ECSCONFIG'
ECS_CLUSTER=${var.cluster_name}
ECS_ENGINE_AUTH_TYPE=docker
ECS_LOGLEVEL=debug
ECS_WARM_POOLS_CHECK=true
ECS_CONTAINER_METADATA_URI_VERSION=v4
ECS_DOCKER_API_VERSION=1.44
ECS_ENABLE_TASK_METADATA=true
ECS_AVAILABLE_LOGGING_DRIVERS=["json-file","awslogs"]
ECS_ENABLE_MANAGED_TAGS=true
ECS_ENABLE_TAG_PROPAGATION=true
ECS_ENABLE_CONTAINER_METADATA=true
ECS_CONTAINER_METADATA_URI=/v3/
ECS_AWSVPC_BLOCK_IMDS=false
ECS_ENABLE_TASK_IAM_ROLE=true
ECS_ENABLE_TASK_ENI=true
ECS_ENABLE_SPOT_INSTANCE_DRAINING=true
ECS_ENABLE_HEALTH_MONITORING=true
ECS_CONTAINER_METADATA_POLL_INTERVAL=60
ECS_STATIC_CONTAINER_PORT_MAPPING=true
ECS_CONTAINER_INSTANCE_TAGS={"environment":"prod","managed-by":"terraform"}
ECS_ENABLE_CONTAINER_INSTANCE_TAGGING=true
ECS_INSTANCE_LOCAL_METADATA_PROVIDER=true
ECSCONFIG


# Install required packages
sudo yum install -y unzip
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
yum install -y amazon-ssm-agent nc jq

# Start and enable SSM Agent
systemctl start amazon-ssm-agent
systemctl enable amazon-ssm-agent

# Configure Session Manager logging
mkdir -p /etc/amazon/ssm
cat > /etc/amazon/ssm/seelog.xml << 'SSMCONFIG'
<seelog type="adaptive" mininterval="2000000" maxinterval="100000000" critmsgcount="500">
    <exceptions>
        <exception filepattern="test*" minlevel="warn"/>
    </exceptions>
    <outputs formatid="fmtinfo">
        <console formatid="fmtinfo"/>
        <rollingfile type="size" filename="/var/log/amazon/ssm/amazon-ssm-agent.log" maxsize="30000000" maxrolls="5"/>
    </outputs>
    <formats>
        <format id="fmtinfo" format="%Date %Time %LEVEL [%FuncShort @ %File.%Line] %Msg%n"/>
    </formats>
</seelog>
SSMCONFIG

# Configure shell profile for Session Manager
cat > /etc/amazon/ssm/shell-config.json << 'SHELLCONFIG'
{
    "linux": {
        "commands": ["bash"],
        "runAsElevated": true,
        "runAsEnabled": true,
        "shellProfile": {
            "linux": "source ~/.bashrc"
        }
    }
}
SHELLCONFIG

# Restart SSM Agent to apply changes
systemctl restart amazon-ssm-agent

# Wait for SSM Agent to stabilize
sleep 30

sudo yum install nano -y

# Verify SSM Agent status
if systemctl is-active amazon-ssm-agent >/dev/null 2>&1; then
    log "SSM Agent is running successfully"
else
    log "Error: SSM Agent failed to start"
    exit 1
fi

log "Setup complete. Verify full configuration in $LOGFILE"
EOT
)


  tag_specifications {
    resource_type = "instance"
    tags = {
      Name       = "${var.ecs_instance_profile_name}-instance"
      ECSCluster = var.cluster_name
    }
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "optional"
    http_put_response_hop_limit = 2
  }

  lifecycle {
    create_before_destroy = true
  }
}










# data "aws_region" "current" {}

# resource "aws_launch_template" "ecs_ec2" {
#   name_prefix   = var.name_prefix
#   image_id      = var.ami_id
#   instance_type = var.instance_type
#   key_name      = var.key_name

#   network_interfaces {
#     subnet_id                   = var.public_subnet_ids[0]
#     associate_public_ip_address = true
#     security_groups            = [var.security_group_id]
#   }

#   iam_instance_profile {
#     arn = var.iam_instance_profile_arn
#   }

#   user_data = base64encode(templatefile("${path.module}/user_data.tpl", {
#     cluster_name       = var.cluster_name
#     log_group_name     = var.log_group_name
#     log_stream_name    = var.log_stream_name
#     region            = data.aws_region.current.name
#     dockerhub_username = var.dockerhub_username
#     dockerhub_password = var.dockerhub_password
#   }))

#   tag_specifications {
#     resource_type = "instance"
#     tags = {
#       Name = "${var.name_prefix}-instance"
#       ECSCluster = var.cluster_name
#     }
#   }

#   metadata_options {
#     http_endpoint               = "enabled"
#     http_tokens                 = "optional"
#     http_put_response_hop_limit = 2
#   }

#   lifecycle {
#     create_before_destroy = true
#   }
# }