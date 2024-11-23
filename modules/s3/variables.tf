# modules/s3/variables.tf
# variable "bucket_name" {
#   description = "Name of the S3 bucket for NGINX configuration"
#   type        = string
# }

# variable "nginx_config_path" {
#   description = "Local path to nginx.conf file"
#   type        = string
# }

# variable "environment" {
#   description = "Environment name (e.g., dev, prod)"
#   type        = string
# }

# variable "task_role_arn" {
#   description = "ARN of the ECS task role that needs access to the S3 bucket"
#   type        = string
# }

variable "bucket_name" {
  description = "Name of the S3 bucket for NGINX configuration"
  type        = string
}
