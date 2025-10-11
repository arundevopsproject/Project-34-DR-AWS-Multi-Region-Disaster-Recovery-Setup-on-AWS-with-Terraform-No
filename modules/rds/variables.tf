variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "primary_vpc_id" {
  description = "ID of the primary VPC"
  type        = string
}

variable "primary_subnet_ids" {
  description = "List of primary subnet IDs"
  type        = list(string)
}

variable "dr_vpc_id" {
  description = "ID of the DR VPC"
  type        = string
}

variable "dr_subnet_ids" {
  description = "List of DR subnet IDs"
  type        = list(string)
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_name" {
  description = "Database name"
  type        = string
}

variable "db_username" {
  description = "Database username"
  type        = string
}