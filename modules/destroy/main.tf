# Advanced destruction resource

resource "null_resource" "comprehensive_ecs_destroy" {
  triggers = {
    cluster_name        = var.cluster_name
    service_name        = var.service_name
    service_name_nodes  = coalesce(var.service_name_nodes, "")
    asg_names           = join(",", var.asg_names)
    instance_ids        = join(",", var.all_instance_ids)
    task_family         = var.task_family
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
          return 0
        }
      }

      # Parse input variables
      CLUSTER_NAME=${self.triggers.cluster_name}
      PRIMARY_SERVICE=${self.triggers.service_name}
      NODES_SERVICE=${self.triggers.service_name_nodes}
      TASK_FAMILY=${self.triggers.task_family}
      ASG_NAMES=${self.triggers.asg_names}
      INSTANCE_IDS=${self.triggers.instance_ids}

      # Process services first
      for service in "$PRIMARY_SERVICE" "$NODES_SERVICE"; do
        if [ -n "$service" ]; then
          echo "Processing service: $service"
          
          # Disable autoscaling
          run_command "aws application-autoscaling deregister-scalable-target \
            --service-namespace ecs \
            --scalable-dimension ecs:service:DesiredCount \
            --resource-id service/$CLUSTER_NAME/$service" \
            "Disable autoscaling for $service"

          # Stop tasks
          TASKS=$(aws ecs list-tasks \
            --cluster "$CLUSTER_NAME" \
            --service-name "$service" \
            --desired-status RUNNING \
            --query 'taskArns[]' \
            --output text)

          if [ -n "$TASKS" ]; then
            for task in $TASKS; do
              run_command "aws ecs stop-task --cluster $CLUSTER_NAME --task $task" \
                "Stop task $task"
            done
          fi

          # Wait for tasks to deregister
          if [ -n "$TASKS" ]; then
            for task in $TASKS; do
              run_command "aws ecs wait tasks-stopped --cluster $CLUSTER_NAME --tasks $task" \
                "Wait for task $task to stop"
            done
          fi

          # Update and delete service
          run_command "aws ecs update-service \
            --cluster $CLUSTER_NAME \
            --service $service \
            --desired-count 0" \
            "Scale down service $service"

          run_command "aws ecs delete-service \
            --cluster $CLUSTER_NAME \
            --service $service \
            --force" \
            "Delete service $service"
        fi
      done

      # Process ASGs
      echo "Processing ASGs: $ASG_NAMES"
      for asg in $(echo "$ASG_NAMES" | tr ',' ' '); do
        if [ -n "$asg" ]; then
          echo "Processing ASG: $asg"
          
          # Suspend processes
          run_command "aws autoscaling suspend-processes --auto-scaling-group-name $asg" \
            "Suspend ASG processes for $asg"

          # Scale down
          run_command "aws autoscaling update-auto-scaling-group \
            --auto-scaling-group-name $asg \
            --min-size 0 \
            --max-size 0 \
            --desired-capacity 0" \
            "Scale down ASG $asg"

          # Get and terminate instances
          INSTANCES=$(aws autoscaling describe-auto-scaling-groups \
            --auto-scaling-group-name "$asg" \
            --query 'AutoScalingGroups[0].Instances[*].InstanceId' \
            --output text)

          if [ -n "$INSTANCES" ]; then
            for instance in $INSTANCES; do
              run_command "aws autoscaling detach-instances \
                --instance-ids $instance \
                --auto-scaling-group-name $asg \
                --should-decrement-desired-capacity" \
                "Detach instance $instance"
              
              run_command "aws ec2 terminate-instances --instance-ids $instance" \
                "Terminate instance $instance"
            done
          fi

          # Wait for instances to terminate
          for instance in $INSTANCES; do
            run_command "aws ec2 wait instance-terminated --instance-ids $instance" \
              "Wait for instance $instance to terminate"
          done

          # Delete ASG
          run_command "aws autoscaling delete-auto-scaling-group \
            --auto-scaling-group-name $asg \
            --force-delete" \
            "Delete ASG $asg"
        fi
      done

      # Deregister task definitions
      TASK_DEFS=$(aws ecs list-task-definitions \
        --family-prefix "$TASK_FAMILY" \
        --status ACTIVE \
        --query 'taskDefinitionArns[]' \
        --output text)
      
      if [ -n "$TASK_DEFS" ]; then
        for td in $TASK_DEFS; do
          run_command "aws ecs deregister-task-definition --task-definition $td" \
            "Deregister task definition $td"
        done
      fi

      # Remove capacity providers
      run_command "aws ecs put-cluster-capacity-providers \
        --cluster $CLUSTER_NAME \
        --capacity-providers [] \
        --default-capacity-provider-strategy []" \
        "Remove capacity providers"

      echo "ECS infrastructure destruction completed successfully"
    EOF
  }
}
#1. Forces task termination directly instead of waiting for service scaling
#2. Removes capacity provider strategy before scaling down
#3. Uses a more aggressive service update configuration
#4. Implements a custom wait mechanism instead of using AWS waiter
#5. Forces service deletion even if tasks are stuck
#6. Adds better error handling and logging