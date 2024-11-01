resource "null_resource" "destroy_ecs_infrastructure" {
  triggers = {
    cluster_name = var.cluster_name
    service_name = var.service_name
    asg_name     = var.asg_name
    task_family  = var.task_family
  }

  provisioner "local-exec" {
    when    = destroy
    interpreter = ["/bin/bash", "-c"]
    command = <<-EOF
      set -e
      echo "Starting ECS infrastructure destruction process..."

      # Step 1: Remove autoscaling
      echo "Removing autoscaling..."
      aws application-autoscaling delete-scaling-policy \
        --service-namespace ecs \
        --resource-id service/${self.triggers.cluster_name}/${self.triggers.service_name} \
        --scalable-dimension ecs:service:DesiredCount \
        --policy-name "*" || true

      aws application-autoscaling deregister-scalable-target \
        --service-namespace ecs \
        --scalable-dimension ecs:service:DesiredCount \
        --resource-id service/${self.triggers.cluster_name}/${self.triggers.service_name} || true

      # Step 2: Stop all tasks forcefully
      echo "Stopping all tasks..."
      TASKS=$(aws ecs list-tasks \
        --cluster "${self.triggers.cluster_name}" \
        --service-name "${self.triggers.service_name}" \
        --desired-status RUNNING \
        --query 'taskArns[]' \
        --output text || echo "")

      for task in $TASKS; do
        echo "Stopping task: $task"
        aws ecs stop-task --cluster "${self.triggers.cluster_name}" --task "$task" || true
      done

      # Step 3: Remove capacity provider strategy
      echo "Removing capacity provider strategy..."
      aws ecs update-service \
        --cluster "${self.triggers.cluster_name}" \
        --service "${self.triggers.service_name}" \
        --capacity-provider-strategy "[]" \
        --force-new-deployment || true

      # Step 4: Scale down service
      echo "Scaling down service..."
      aws ecs update-service \
        --cluster "${self.triggers.cluster_name}" \
        --service "${self.triggers.service_name}" \
        --desired-count 0 \
        --deployment-configuration '{"maximumPercent":100,"minimumHealthyPercent":0}' || true

      # Step 5: Wait for tasks to stop with timeout
      echo "Waiting for tasks to stop..."
      attempt=0
      max_attempts=30
      while [ $attempt -lt $max_attempts ]; do
        RUNNING_COUNT=$(aws ecs describe-services \
          --cluster "${self.triggers.cluster_name}" \
          --services "${self.triggers.service_name}" \
          --query 'services[0].runningCount' \
          --output text)
        
        if [ "$RUNNING_COUNT" = "0" ]; then
          echo "All tasks stopped"
          break
        fi
        
        echo "Tasks still running: $RUNNING_COUNT. Attempt $((attempt+1))/$max_attempts"
        sleep 10
        attempt=$((attempt+1))
      done

      # Step 6: Force delete the service
      echo "Force deleting service..."
      aws ecs delete-service \
        --cluster "${self.triggers.cluster_name}" \
        --service "${self.triggers.service_name}" \
        --force || true

      # Step 7: Deregister task definitions
      echo "Deregistering task definitions..."
      TASK_DEFS=$(aws ecs list-task-definitions \
        --family-prefix "${self.triggers.task_family}" \
        --status ACTIVE \
        --query 'taskDefinitionArns[]' \
        --output text || echo "")
      
      for td in $TASK_DEFS; do
        echo "Deregistering task definition: $td"
        aws ecs deregister-task-definition --task-definition "$td" || true
      done

      # Step 8: Detach capacity providers
      echo "Detaching capacity providers..."
      aws ecs put-cluster-capacity-providers \
        --cluster "${self.triggers.cluster_name}" \
        --capacity-providers [] \
        --default-capacity-provider-strategy [] || true

      # Step 9: Scale down ASG
      echo "Scaling down ASG..."
      aws autoscaling update-auto-scaling-group \
        --auto-scaling-group-name "${self.triggers.asg_name}" \
        --min-size 0 \
        --max-size 0 \
        --desired-capacity 0 || true

      # Step 10: Force terminate instances
      echo "Force terminating instances..."
      INSTANCE_IDS=$(aws autoscaling describe-auto-scaling-groups \
        --auto-scaling-group-name "${self.triggers.asg_name}" \
        --query 'AutoScalingGroups[0].Instances[*].InstanceId' \
        --output text || echo "")

      for id in $INSTANCE_IDS; do
        echo "Detaching and terminating instance: $id"
        aws autoscaling detach-instances \
          --instance-ids "$id" \
          --auto-scaling-group-name "${self.triggers.asg_name}" \
          --should-decrement-desired-capacity || true
        
        aws ec2 terminate-instances --instance-ids "$id" || true
      done

      echo "Waiting for instance termination..."
      sleep 30

      echo "ECS infrastructure destruction process completed"
    EOF
  }
}

#1. Forces task termination directly instead of waiting for service scaling
#2. Removes capacity provider strategy before scaling down
#3. Uses a more aggressive service update configuration
#4. Implements a custom wait mechanism instead of using AWS waiter
#5. Forces service deletion even if tasks are stuck
#6. Adds better error handling and logging