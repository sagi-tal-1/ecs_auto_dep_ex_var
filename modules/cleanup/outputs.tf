# modules/cleanup/outputs.tf
output "cleanup_status" {
  description = "Status of the cleanup operation"
  value       = var.cleanup_enabled ? "Cleanup enabled" : "Cleanup not required"
}