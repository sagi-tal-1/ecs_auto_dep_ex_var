variable "name_prefix" {
  description = "Name prefix for the log group"
  type        = string
}

variable "retention_in_days" {
  description = "Number of days to retain log events"
  type        = number
  default     = 7
}


