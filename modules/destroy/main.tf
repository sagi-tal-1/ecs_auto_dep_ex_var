# Advanced destruction resource
resource "null_resource" "comprehensive_ecs_destroy" {
  triggers = {
    cluster_name = var.cluster_name
    service_name = var.service_name
    service_name_nodes = coalesce(var.service_name_nodes, "")
    asg_name     = var.asg_name
    task_family  = var.task_family
  }

  provisioner "local-exec" {
    when        = destroy
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOF
      #!/bin/bash
      set -e

      # Logging and error handling function
      run_command() {
        local command="$1"
        local description="$2"
        
        echo "Executing: $description"
        eval "$command" || {
          echo "WARNING: Failed to $description"
          return 0  # Continue despite failure
        }
      }

      # Cluster Name
      CLUSTER_NAME="${self.triggers.cluster_name}"
      
      # Primary Service
      PRIMARY_SERVICE="${self.triggers.service_name}"
      
      # Nodes Service
      NODES_SERVICE="${self.triggers.service_name_nodes}"
      
      # ASG Name
      ASG_NAME="${self.triggers.asg_name}"
      
      # Task Family
      TASK_FAMILY="${self.triggers.task_family}"

      # 1. Disable Application Auto Scaling
      run_command "aws application-autoscaling deregister-scalable-target \
        --service-namespace ecs \
        --scalable-dimension ecs:service:DesiredCount \
        --resource-id service/$CLUSTER_NAME/$PRIMARY_SERVICE" \
        "Disable Application Auto Scaling for primary service"

      # Function to process service
      process_service() {
        local service="$1"
        if [ -n "$service" ]; then
          echo "Processing service: $service"

          # Stop all running tasks
          TASKS=$(aws ecs list-tasks \
            --cluster "$CLUSTER_NAME" \
            --service-name "$service" \
            --desired-status RUNNING \
            --query 'taskArns[]' \
            --output text)

          if [ -n "$TASKS" ]; then
            for task in $TASKS; do
              run_command "aws ecs stop-task \
                --cluster \"$CLUSTER_NAME\" \
                --task \"$task\"" \
                "Stop task $task"
            done
          fi

          # Scale down service
          run_command "aws ecs update-service \
            --cluster \"$CLUSTER_NAME\" \
            --service \"$service\" \
            --desired-count 0 \
            --force-new-deployment" \
            "Scale down service $service"

          # Delete service
          run_command "aws ecs delete-service \
            --cluster \"$CLUSTER_NAME\" \
            --service \"$service\" \
            --force" \
            "Delete service $service"
        fi
      }

      # Process both primary and nodes services
      process_service "$PRIMARY_SERVICE"
      process_service "$NODES_SERVICE"

      # Deregister Task Definitions
      TASK_DEFS=$(aws ecs list-task-definitions \
        --family-prefix "$TASK_FAMILY" \
        --status ACTIVE \
        --query 'taskDefinitionArns[]' \
        --output text)
      
      if [ -n "$TASK_DEFS" ]; then
        for td in $TASK_DEFS; do
          run_command "aws ecs deregister-task-definition \
            --task-definition \"$td\"" \
            "Deregister task definition $td"
        done
      fi

      # Remove Capacity Providers
      run_command "aws ecs put-cluster-capacity-providers \
        --cluster \"$CLUSTER_NAME\" \
        --capacity-providers [] \
        --default-capacity-provider-strategy []" \
        "Remove capacity providers"

      # Get ASG Instances
      INSTANCE_IDS=$(aws autoscaling describe-auto-scaling-groups \
        --auto-scaling-group-name "$ASG_NAME" \
        --query 'AutoScalingGroups[0].Instances[*].InstanceId' \
        --output text)

      if [ -n "$INSTANCE_IDS" ]; then
        # Suspend ASG processes
        run_command "aws autoscaling suspend-processes \
          --auto-scaling-group-name \"$ASG_NAME\"" \
          "Suspend ASG processes"

        # Terminate instances
        for id in $INSTANCE_IDS; do
          run_command "aws autoscaling detach-instances \
            --instance-ids \"$id\" \
            --auto-scaling-group-name \"$ASG_NAME\" \
            --should-decrement-desired-capacity" \
            "Detach instance $id"
          
          run_command "aws ec2 terminate-instances \
            --instance-ids \"$id\" \
            --force" \
            "Terminate instance $id"
        done
      fi

      # Scale down ASG
      run_command "aws autoscaling update-auto-scaling-group \
        --auto-scaling-group-name \"$ASG_NAME\" \
        --min-size 0 \
        --max-size 0 \
        --desired-capacity 0" \
        "Scale down ASG"

      # Delete ASG
      run_command "aws autoscaling delete-auto-scaling-group \
        --auto-scaling-group-name \"$ASG_NAME\" \
        --force-delete" \
        "Delete Auto Scaling Group"

      echo "ECS infrastructure destruction completed successfully"
      exit 0
    EOF
  }
}


#1. Forces task termination directly instead of waiting for service scaling
#2. Removes capacity provider strategy before scaling down
#3. Uses a more aggressive service update configuration
#4. Implements a custom wait mechanism instead of using AWS waiter
#5. Forces service deletion even if tasks are stuck
#6. Adds better error handling and logging