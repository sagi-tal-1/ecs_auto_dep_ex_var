# resource "null_resource" "destroy_sequence" {
#   triggers = {
#     cluster_name = var.name_prefix
#   }

#   provisioner "local-exec" {
#     when    = destroy
#     command = <<-EOF
#       #!/bin/bash
#       set -e
#       echo "Starting ECS infrastructure cleanup process..."

#       CLUSTER_NAME="${self.triggers.cluster_name}-cluster"
#       SERVICE_NAME="${self.triggers.cluster_name}-ecs-service"
#       REGION="${var.aws_region}"

#       echo "Cluster Name: $CLUSTER_NAME"
#       echo "Service Name: $SERVICE_NAME"
#       echo "Region: $REGION"

#       # Force delete the service
#       echo "Updating service to 0 desired count..."
#       aws ecs update-service --cluster $CLUSTER_NAME --service $SERVICE_NAME --desired-count 0 --region $REGION
#       echo "Force deleting ECS service..."
#       aws ecs delete-service --cluster $CLUSTER_NAME --service $SERVICE_NAME --force --region $REGION
#       echo "Service deletion initiated."

#       # Deregister all task definitions
#       echo "Listing task definitions..."
#       TASK_DEFINITIONS=$(aws ecs list-task-definitions --family-prefix $SERVICE_NAME --region $REGION --query 'taskDefinitionArns[]' --output text)
#       echo "Task Definitions found: $TASK_DEFINITIONS"
#       for TD in $TASK_DEFINITIONS; do
#         echo "Deregistering task definition: $TD"
#         aws ecs deregister-task-definition --task-definition $TD --region $REGION
#       done

#       # Stop all tasks
#       echo "Listing tasks in cluster..."
#       TASKS=$(aws ecs list-tasks --cluster $CLUSTER_NAME --region $REGION --query 'taskArns[]' --output text)
#       echo "Tasks found: $TASKS"
#       if [ ! -z "$TASKS" ]; then
#         for TASK in $TASKS; do
#           echo "Stopping task: $TASK"
#           aws ecs stop-task --cluster $CLUSTER_NAME --task $TASK --region $REGION
#         done
#       else
#         echo "No tasks found to stop."
#       fi

#       # Deregister all container instances
#       echo "Listing container instances..."
#       INSTANCES=$(aws ecs list-container-instances --cluster $CLUSTER_NAME --region $REGION --query 'containerInstanceArns[]' --output text)
#       echo "Container instances found: $INSTANCES"
#       if [ ! -z "$INSTANCES" ]; then
#         for INSTANCE in $INSTANCES; do
#           echo "Deregistering container instance: $INSTANCE"
#           aws ecs deregister-container-instance --cluster $CLUSTER_NAME --container-instance $INSTANCE --force --region $REGION
#         done
#       else
#         echo "No container instances found to deregister."
#       fi

#       # Remove capacity providers from the cluster
#       echo "Describing cluster to find capacity providers..."
#       CAPACITY_PROVIDERS=$(aws ecs describe-clusters --clusters $CLUSTER_NAME --region $REGION --query 'clusters[0].capacityProviders[]' --output text)
#       echo "Capacity providers found: $CAPACITY_PROVIDERS"
#       if [ ! -z "$CAPACITY_PROVIDERS" ]; then
#         echo "Removing capacity providers from the cluster..."
#         aws ecs put-cluster-capacity-providers --cluster $CLUSTER_NAME --capacity-providers [] --default-capacity-provider-strategy [] --region $REGION
#       else
#         echo "No capacity providers found to remove."
#       fi

#       # Delete the cluster
#       echo "Deleting ECS cluster..."
#       aws ecs delete-cluster --cluster $CLUSTER_NAME --region $REGION
#       echo "Cluster deletion initiated."

#       echo "ECS infrastructure cleanup completed successfully."
#     EOF
#   }

#   depends_on = [module.ecs_service]
# }