variable "log_group_name" {
  description = "Name of the CloudWatch Log Group."
  type        = string
}

variable "retention_days" {
  description = "Number of days to retain log data."
  type        = number
  default     = 1
}
