output "primary_bucket_name" {
  description = "Name of the primary S3 bucket"
  value       = aws_s3_bucket.primary.bucket
}

output "primary_bucket_arn" {
  description = "ARN of the primary S3 bucket"
  value       = aws_s3_bucket.primary.arn
}

output "replica_bucket_name" {
  description = "Name of the replica S3 bucket"
  value       = aws_s3_bucket.dr.bucket
}

output "replica_bucket_arn" {
  description = "ARN of the replica S3 bucket"
  value       = aws_s3_bucket.dr.arn
}

output "primary_kms_key_id" {
  description = "ID of the primary KMS key"
  value       = aws_kms_key.s3_primary.key_id
}

output "dr_kms_key_id" {
  description = "ID of the DR KMS key"
  value       = aws_kms_key.s3_dr.key_id
}