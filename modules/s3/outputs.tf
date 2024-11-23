# modules/s3/outputs.tf


output "bucket_arn" {
  description = "ARN of the created S3 bucket"
  value       = aws_s3_bucket.nginx_config.arn
}


# Output the bucket name
output "bucket_name" {
  value       = aws_s3_bucket.nginx_config.id
  description = "Name of the S3 bucket containing NGINX configuration"
}
output "bucket_region" {
  value       = aws_s3_bucket.nginx_config.region
  description = "Region of the S3 bucket"
}