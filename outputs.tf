output "primary_vpc_id" {
  description = "ID of the primary VPC"
  value       = module.primary_vpc.vpc_id
}

output "dr_vpc_id" {
  description = "ID of the DR VPC"
  value       = module.dr_vpc.vpc_id
}

output "primary_alb_dns_name" {
  description = "DNS name of the primary ALB"
  value       = module.primary_app.alb_dns_name
}

output "dr_alb_dns_name" {
  description = "DNS name of the DR ALB"
  value       = module.dr_app.alb_dns_name
}

output "rds_primary_endpoint" {
  description = "RDS primary instance endpoint"
  value       = module.rds.primary_endpoint
  sensitive   = true
}

output "rds_replica_endpoint" {
  description = "RDS read replica endpoint"
  value       = module.rds.replica_endpoint
  sensitive   = true
}

output "s3_primary_bucket" {
  description = "Primary S3 bucket name"
  value       = module.s3_replication.primary_bucket_name
}

output "s3_replica_bucket" {
  description = "Replica S3 bucket name"
  value       = module.s3_replication.replica_bucket_name
}

output "route53_zone_id" {
  description = "Route 53 hosted zone ID"
  value       = module.route53.zone_id
}

output "application_url" {
  description = "Application URL"
  value       = "https://${var.domain_name}"
}