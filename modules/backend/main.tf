#moduls/backend/main.tf



resource "random_id" "unique" {
  byte_length = 8
}

# S3 bucket for storing Terraform state files
resource "aws_s3_bucket" "terraform_state" {
   bucket        = lower("${var.environment}-tfstate-${random_id.unique.hex}")
  force_destroy = true # This allows Terraform to delete the bucket even if it contains objects
   
   tags = {
    Environment = var.environment
    Project     = var.project_name
  }

}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Add lifecycle rule to clean up old versions
resource "aws_s3_bucket_lifecycle_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    id     = "cleanup_old_versions"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = 1
    }

    #object versioning control.
    abort_incomplete_multipart_upload {
    days_after_initiation = 7
    }

    expiration {
      expired_object_delete_marker = true
    }
  
  }
}


resource "aws_dynamodb_table" "terraform_locks" {
  name         = var.table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name = var.table_name
  }

  # lifecycle {
  #   prevent_destroy = true
  # }
}
