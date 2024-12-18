variable "task_role_name_prefix" {
  description = "Prefix for the ECS Task Role name."
  type        = string
}

variable "exec_role_name_prefix" {
  description = "Prefix for the ECS Task Execution Role name."
  type        = string
}
variable "nginx_config_bucket_name" {
  description = "Name of the S3 bucket containing nginx configuration"
  type        = string
}
