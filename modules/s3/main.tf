locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# KMS Key for S3 encryption
resource "aws_kms_key" "s3_primary" {
  provider = aws.primary

  description             = "KMS key for S3 bucket encryption in primary region"
  deletion_window_in_days = 7

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-s3-primary-key"
  })
}

resource "aws_kms_alias" "s3_primary" {
  provider = aws.primary

  name          = "alias/${var.project_name}-${var.environment}-s3-primary"
  target_key_id = aws_kms_key.s3_primary.key_id
}

resource "aws_kms_key" "s3_dr" {
  provider = aws.dr

  description             = "KMS key for S3 bucket encryption in DR region"
  deletion_window_in_days = 7

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-s3-dr-key"
  })
}

resource "aws_kms_alias" "s3_dr" {
  provider = aws.dr

  name          = "alias/${var.project_name}-${var.environment}-s3-dr"
  target_key_id = aws_kms_key.s3_dr.key_id
}

# Primary S3 bucket
resource "aws_s3_bucket" "primary" {
  provider = aws.primary

  bucket = "${var.project_name}-${var.environment}-primary-${random_id.bucket_suffix.hex}"

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-primary"
  })
}

# DR S3 bucket
resource "aws_s3_bucket" "dr" {
  provider = aws.dr

  bucket = "${var.project_name}-${var.environment}-dr-${random_id.bucket_suffix.hex}"

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-dr"
  })
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# S3 bucket versioning
resource "aws_s3_bucket_versioning" "primary" {
  provider = aws.primary

  bucket = aws_s3_bucket.primary.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_versioning" "dr" {
  provider = aws.dr

  bucket = aws_s3_bucket.dr.id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 bucket encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "primary" {
  provider = aws.primary

  bucket = aws_s3_bucket.primary.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.s3_primary.arn
      sse_algorithm     = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "dr" {
  provider = aws.dr

  bucket = aws_s3_bucket.dr.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.s3_dr.arn
      sse_algorithm     = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

# S3 bucket public access block
resource "aws_s3_bucket_public_access_block" "primary" {
  provider = aws.primary

  bucket = aws_s3_bucket.primary.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "dr" {
  provider = aws.dr

  bucket = aws_s3_bucket.dr.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# IAM role for replication
resource "aws_iam_role" "replication" {
  provider = aws.primary

  name = "${var.project_name}-${var.environment}-s3-replication-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_policy" "replication" {
  provider = aws.primary

  name = "${var.project_name}-${var.environment}-s3-replication-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObjectVersionForReplication",
          "s3:GetObjectVersionAcl",
          "s3:GetObjectVersionTagging"
        ]
        Effect = "Allow"
        Resource = "${aws_s3_bucket.primary.arn}/*"
      },
      {
        Action = [
          "s3:ListBucket"
        ]
        Effect = "Allow"
        Resource = aws_s3_bucket.primary.arn
      },
      {
        Action = [
          "s3:ReplicateObject",
          "s3:ReplicateDelete",
          "s3:ReplicateTags"
        ]
        Effect = "Allow"
        Resource = "${aws_s3_bucket.dr.arn}/*"
      },
      {
        Action = [
          "kms:Decrypt"
        ]
        Effect = "Allow"
        Resource = aws_kms_key.s3_primary.arn
      },
      {
        Action = [
          "kms:GenerateDataKey"
        ]
        Effect = "Allow"
        Resource = aws_kms_key.s3_dr.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "replication" {
  provider = aws.primary

  role       = aws_iam_role.replication.name
  policy_arn = aws_iam_policy.replication.arn
}

# S3 bucket replication configuration
resource "aws_s3_bucket_replication_configuration" "replication" {
  provider = aws.primary

  role   = aws_iam_role.replication.arn
  bucket = aws_s3_bucket.primary.id

  rule {
    id     = "ReplicateEverything"
    status = "Enabled"

    destination {
      bucket        = aws_s3_bucket.dr.arn
      storage_class = "STANDARD_IA"

      encryption_configuration {
        replica_kms_key_id = aws_kms_key.s3_dr.arn
      }
    }
  }

  depends_on = [aws_s3_bucket_versioning.primary]
}

# S3 bucket lifecycle configuration
resource "aws_s3_bucket_lifecycle_configuration" "primary" {
  provider = aws.primary

  bucket = aws_s3_bucket.primary.id

  rule {
    id     = "lifecycle"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "dr" {
  provider = aws.dr

  bucket = aws_s3_bucket.dr.id

  rule {
    id     = "lifecycle"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }
}