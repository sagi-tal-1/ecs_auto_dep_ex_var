# Use Python slim image for a smaller footprint
FROM python:3.9-slim

# Set working directory
WORKDIR /app

# Copy requirements and install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the script
COPY ecs_ip_finder.py .

# Set environment variables (these will be overridden at runtime)
ENV AWS_ACCESS_KEY_ID=""
ENV AWS_SECRET_ACCESS_KEY=""
ENV AWS_DEFAULT_REGION=""
ENV CLUSTER_NAME=""
ENV SERVICE_NAME=""

# Create entrypoint script
RUN echo '#!/bin/sh\n\
if [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ] || [ -z "$AWS_DEFAULT_REGION" ] || [ -z "$CLUSTER_NAME" ] || [ -z "$SERVICE_NAME" ]; then\n\
    echo "Error: Required environment variables are not set"\n\
    echo "Please set: AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_DEFAULT_REGION, CLUSTER_NAME, SERVICE_NAME"\n\
    exit 1\n\
fi\n\
python ecs_ip_finder.py' > /app/entrypoint.sh && chmod +x /app/entrypoint.sh

# Set the entrypoint
ENTRYPOINT ["/app/entrypoint.sh"]


##############


requirements.txt
boto3==1.28.0
botocore>=1.31.0

###ecs-ip-finder.py 


import boto3
import os
from typing import Dict, Optional

def get_task_and_host_details(cluster_name: str, service_name: str) -> list[Dict]:
    """
    Get task and host details for tasks in an ECS service
    """
    ecs_client = boto3.client('ecs')
    ec2_client = boto3.client('ec2')
    results = []

    # Get tasks for the service
    tasks = ecs_client.list_tasks(
        cluster=cluster_name,
        serviceName=service_name
    )

    if not tasks['taskArns']:
        print(f"No tasks found for service {service_name}")
        return results

    # Get detailed task information
    task_details = ecs_client.describe_tasks(
        cluster=cluster_name,
        tasks=tasks['taskArns']
    )

    for task in task_details['tasks']:
        task_info = {
            'taskArn': task['taskArn'],
            'taskIp': None,
            'hostIp': None,
            'status': task['lastStatus']
        }

        # Get network interface ID for the task
        for attachment in task.get('attachments', []):
            if attachment['type'] == 'ElasticNetworkInterface':
                for detail in attachment['details']:
                    if detail['name'] == 'networkInterfaceId':
                        eni_id = detail['value']
                        # Get IP information from the network interface
                        eni_info = ec2_client.describe_network_interfaces(
                            NetworkInterfaceIds=[eni_id]
                        )
                        if eni_info['NetworkInterfaces']:
                            interface = eni_info['NetworkInterfaces'][0]
                            task_info['taskIp'] = interface.get('PrivateIpAddress')
                            
                            # Get public IP if available
                            if 'Association' in interface:
                                task_info['publicIp'] = interface['Association'].get('PublicIp')

        # Get container instance details (for EC2 launch type)
        if 'containerInstanceArn' in task:
            container_instances = ecs_client.describe_container_instances(
                cluster=cluster_name,
                containerInstances=[task['containerInstanceArn']]
            )
            
            if container_instances['containerInstances']:
                ec2_instance_id = container_instances['containerInstances'][0]['ec2InstanceId']
                ec2_instances = ec2_client.describe_instances(
                    InstanceIds=[ec2_instance_id]
                )
                
                if ec2_instances['Reservations']:
                    instance = ec2_instances['Reservations'][0]['Instances'][0]
                    task_info['hostIp'] = instance.get('PrivateIpAddress')

        results.append(task_info)

    return results

def main():
    # Get configuration from environment variables
    cluster_name = os.environ.get('CLUSTER_NAME')
    service_name = os.environ.get('SERVICE_NAME')

    try:
        task_details = get_task_and_host_details(cluster_name, service_name)
        
        for task in task_details:
            print(f"\nTask ARN: {task['taskArn']}")
            print(f"Status: {task['status']}")
            print(f"Task IP: {task['taskIp']}")
            if 'publicIp' in task:
                print(f"Task Public IP: {task['publicIp']}")
            print(f"Host IP: {task['hostIp']}")
            print("-" * 50)

    except Exception as e:
        print(f"Error: {str(e)}")

if __name__ == "__main__":
    main()



    docker build -t ecs-ip-finder .


boto3==1.28.0
docker run -e AWS_ACCESS_KEY_ID="AKIAQE5S7C332HWKLRGS" \
-e AWS_SECRET_ACCESS_KEY="REMOVED_SECRET" \
-e AWS_DEFAULT_REGION="us-east-1" \
my-nginx-proxy



docker run -e AWS_ACCESS_KEY_ID="AKIAQE5S7C332HWKLRGS" \
           -e AWS_SECRET_ACCESS_KEY="REMOVED_SECRET" \
           -e AWS_DEFAULT_REGION="your-region" \
           -e CLUSTER_NAME="us-east-1" \
           -e SERVICE_NAME="ECS_service-ecs-service-node-b9d39ad0" \
           -p 80:80 \
           nginx-proxy23


           ONTAINER ID   IMAGE                                COMMAND                  CREATED          STATUS                 PORTS                                       NAMES

           38a30d0b14f   awsemc1980/express-identity:latest   "docker-entrypoint.s…"   6 minutes ago   Up 6 minutes             0.0.0.0:3000->3000/tcp, :::3000->3000/tcp   ecs-node-task-4e7567d0-1-my-container-nodejs-a8e8c5d2a4f58c962500



           docker run -it --rm \
    -e AWS_ACCESS_KEY_ID="AKIAQE5S7C332HWKLRGS" \
    -e AWS_SECRET_ACCESS_KEY="REMOVED_SECRET" \
    -e AWS_DEFAULT_REGION="us-east-1" \
    -e CLUSTER_NAME="demo-cluster-3b1053f4" \
    -e SERVICE_NAME="yECS_service-ecs-service-node-3b1053f4" \
    -p 80:80 \
    my-nginx-proxy23


    FROM nginx:alpine

RUN apk add --no-cache aws-cli jq curl

COPY entrypoint.sh /entrypoint.sh
COPY nginx.conf.template /etc/nginx/nginx.conf.template

RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]

(entrypoint.sh):

  #!/bin/sh
  
  # Get task IP using AWS CLI
  TASK_IP=$(aws ecs list-tasks --cluster ${CLUSTER_NAME} --service-name ${SERVICE_NAME} \
      | jq -r '.taskArns[0]' \
      | xargs aws ecs describe-tasks --cluster ${CLUSTER_NAME} --tasks \
      | jq -r '.tasks[0].containers[0].networkInterfaces[0].privateIpv4Address')
  
  # Replace placeholder in nginx config
  sed "s/TASK_IP/${TASK_IP}/g" /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf
  
  # Start nginx
  docker run -it --rm \
  -e AWS_ACCESS_KEY_ID="AKIAQE5S7C332HWKLRGS" \
  -e AWS_SECRET_ACCESS_KEY="REMOVED_SECRET" \
      -e AWS_DEFAULT_REGION="us-east-1" \
      -e CLUSTER_NAME="demo-ecs-Nservice-3b1053f4" \
      -e SERVICE_NAME="ECS_service-ecs-service-node-3b1053f4" \
      -p 80:80 \
      my-nginx-proxyv13
  



      docker run -it --rm \
  -e AWS_DEFAULT_REGION="us-east-1" \
  -e CLUSTER_NAME="demo-cluster-cb1c3745" \
  -e SERVICE_NAME="ECS_service-ecs-service-node-cb1c3745" \
  -e NAMESPACE="ns-76kkyk3g7kfhngfs" \
  -p 80:80 \
  my-nginx-proxy22


  docker run -d \
  -e AWS_ACCESS_KEY_ID="$(aws configure get aws_access_key_id)" \
  -e AWS_SECRET_ACCESS_KEY="$(aws configure get aws_secret_access_key)" \
  -e AWS_DEFAULT_REGION="us-east-1" \
  -e CLUSTER_NAME="demo-cluster-cb1c3745" \
  -e SERVICE_NAME="ECS_service-ecs-service-node-cb1c3745 " \
  -p 80:80 \
  nginx-proxy23



  aws ecs run-task \
    --cluster my-cluster \
    --task-definition nginx-proxy:1 \
    --overrides '{"containerOverrides": [{"name": "nginx-proxy", "environment": [
        {"name": "ECS_CLUSTER_NAME", "value": "demo-cluster-32adfc71"},
        {"name": "ECS_SERVICE_NAME", "value": "ECS_service-ecs-service-node-32adfc71"},
        {"name": "ECS_CONTAINER_NAME", "value": "my-container-nodejs"},
        {"name": "BACKEND_PORT", "value": "3000"}
    ]}]}'



      FROM nginx:alpine

      RUN apk add --no-cache aws-cli jq curl
      
      COPY entrypoint.sh /entrypoint.sh
      COPY nginx.conf.template /etc/nginx/nginx.conf.template
      
      RUN chmod +x /entrypoint.sh
      
      ENTRYPOINT ["/entrypoint.sh"]
      





      (entrypoint.sh):

        #!/bin/sh
        
        # Get task IP using AWS CLI
        TASK_IP=$(aws ecs list-tasks --cluster ${CLUSTER_NAME} --service-name ${SERVICE_NAME} \
            | jq -r '.taskArns[0]' \
            | xargs aws ecs describe-tasks --cluster ${CLUSTER_NAME} --tasks \
            | jq -r '.tasks[0].containers[0].networkInterfaces[0].privateIpv4Address')
        
        # Replace placeholder in nginx config
        sed "s/TASK_IP/${TASK_IP}/g" /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf
        
        # Start nginx
        nginx -g 'daemon off;'



      nginx.conf.template:

        events {
            worker_connections 1024;
        }
        
        http {
            upstream backend {
                server TASK_IP:3000;
            }
        
            server {
                listen 80;
                
                location / {
                    proxy_pass http://backend;
                    proxy_set_header Host $host;
                    proxy_set_header X-Real-IP $remote_addr;
                }
            }
        }













        CONTAINER ID   IMAGE                                                            COMMAND                  CREATED          STATUS                 PORTS                                       NAMES

28b8dbacb7c0   awsemc1980/express-identity:latest                               "docker-entrypoint.s…"   2 hours ago      Up 2 hours             0.0.0.0:3000->3000/tcp, :::3000->3000/tcp   ecs-node-task-b8787108-1-my-container-nodejs-8cd099cc9b8f868c3000
a19c293eaa89   amazon/amazon-ecs-agent:latest                                   "/agent"                 2 hours ago      Up 2 hours (healthy)                                               ecs-agent
[ec2-user@ip-10-0-3-45 ~]$