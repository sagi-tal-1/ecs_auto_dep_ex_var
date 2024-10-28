# modules/cleanup/main.tf
resource "null_resource" "cleanup" {
  triggers = {
    cluster_name = var.cluster_name
    service_name = var.service_name
    asg_name     = var.asg_name
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOF
      # Detach capacity providers
      aws ecs put-cluster-capacity-providers \
        --cluster ${var.cluster_name} \
        --capacity-providers [] \
        --default-capacity-provider-strategy [] || true

      # Wait for service to be inactive
      aws ecs wait services-inactive \
        --cluster ${var.cluster_name} \
        --services ${var.service_name} || true

      # Clean up ASG instances
      INSTANCE_IDS=$(aws autoscaling describe-auto-scaling-groups \
        --auto-scaling-group-name ${var.asg_name} \
        --query 'AutoScalingGroups[0].Instances[*].InstanceId' \
        --output text)

      for ID in $INSTANCE_IDS; do
        aws ec2 terminate-instances --instance-ids $ID || true
      done
    EOF
  }
}

# modules/internet_gateway/main.tf
resource "aws_internet_gateway" "main" {
  # ... existing configuration ...

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_eip" "main" {
  # ... existing configuration ...

  lifecycle {
    create_before_destroy = true
  }

  provisioner "local-exec" {
    when    = destroy
    command = "aws ec2 release-address --allocation-id ${self.id} || true"
  }
}
