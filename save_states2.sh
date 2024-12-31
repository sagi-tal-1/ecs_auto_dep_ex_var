#!/bin/bash

echo "Saving Terraform state outputs to terraform_state_output.txt..."

# Save the state of Auto Scaling Group
terraform state show module.ecs_asg.aws_autoscaling_group.ecs >> terraform_state_outputasg.txt

echo "State outputs saved successfully."

