#!/bin/bash

echo "Saving Terraform state outputs to terraform_state_output.txt..."

# Save the state of ECS service
terraform state show module.ecs_service.aws_ecs_service.app >> terraform_state_output.txt

# Save the state of ECS cluster
terraform state show module.ecs_cluster.aws_ecs_cluster.main >> terraform_state_output.txt

# Save the state of ECS service nodes
terraform state show module.ecs_service_nodes.aws_ecs_service.nodejs >> terraform_state_output.txt

# Save the state of ECS task definition (Node.js)
terraform state show module.ecs_task_definition_node.aws_ecs_task_definition.app >> terraform_state_output.txt

# Save the state of ECS task definition (main app)
terraform state show module.ecs_task_definition.aws_ecs_task_definition.app >> terraform_state_output.txt

# Save the state of Auto Scaling Group
terraform state show module.ecs_asg.aws_autoscaling_group.ecs >> terraform_state_output.txt

echo "State outputs saved successfully."

