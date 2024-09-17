variable "name_prefix" {
  description = "Name prefix for the log group"
  type        = string
}

variable "retention_in_days" {
  description = "Number of days to retain log events"
  type        = number
  default     = 7
}

variable "name" {
  description = "Name of the log stream"
  type        = string
}

variable "log_group_name" {
  description = "Name of the log group to create the stream in"
  type        = string
}
