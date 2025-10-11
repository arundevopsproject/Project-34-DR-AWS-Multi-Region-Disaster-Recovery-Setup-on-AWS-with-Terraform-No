variable "domain_name" {
  description = "Domain name for the application"
  type        = string
}

variable "primary_alb_dns_name" {
  description = "DNS name of the primary ALB"
  type        = string
}

variable "primary_alb_zone_id" {
  description = "Zone ID of the primary ALB"
  type        = string
}

variable "dr_alb_dns_name" {
  description = "DNS name of the DR ALB"
  type        = string
}

variable "dr_alb_zone_id" {
  description = "Zone ID of the DR ALB"
  type        = string
}

variable "health_check_path" {
  description = "Path for health checks"
  type        = string
  default     = "/health"
}