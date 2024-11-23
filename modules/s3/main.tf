# modules/s3/main.tf

# S3 Bucket
resource "aws_s3_bucket" "nginx_config" {
  bucket = var.bucket_name
}

# Enable versioning
resource "aws_s3_bucket_versioning" "nginx_config" {
  bucket = aws_s3_bucket.nginx_config.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Block public access
resource "aws_s3_bucket_public_access_block" "nginx_config" {
  bucket = aws_s3_bucket.nginx_config.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "nginx_config" {
  bucket = aws_s3_bucket.nginx_config.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
