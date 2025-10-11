locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# Generate random password for RDS
resource "random_password" "db_password" {
  length  = 16
  special = true
}

# Store password in AWS Secrets Manager
resource "aws_secretsmanager_secret" "db_password" {
  provider = aws.primary

  name        = "${var.project_name}-${var.environment}-db-password"
  description = "Database password for ${var.project_name}"

  tags = local.common_tags
}

resource "aws_secretsmanager_secret_version" "db_password" {
  provider = aws.primary

  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = random_password.db_password.result
}

# KMS key for RDS encryption
resource "aws_kms_key" "rds_primary" {
  provider = aws.primary

  description             = "KMS key for RDS encryption in primary region"
  deletion_window_in_days = 7

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-rds-primary-key"
  })
}

resource "aws_kms_alias" "rds_primary" {
  provider = aws.primary

  name          = "alias/${var.project_name}-${var.environment}-rds-primary"
  target_key_id = aws_kms_key.rds_primary.key_id
}

resource "aws_kms_key" "rds_dr" {
  provider = aws.dr

  description             = "KMS key for RDS encryption in DR region"
  deletion_window_in_days = 7

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-rds-dr-key"
  })
}

resource "aws_kms_alias" "rds_dr" {
  provider = aws.dr

  name          = "alias/${var.project_name}-${var.environment}-rds-dr"
  target_key_id = aws_kms_key.rds_dr.key_id
}

# DB Subnet Groups
resource "aws_db_subnet_group" "primary" {
  provider = aws.primary

  name       = "${var.project_name}-${var.environment}-primary-subnet-group"
  subnet_ids = var.primary_subnet_ids

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-primary-subnet-group"
  })
}

resource "aws_db_subnet_group" "dr" {
  provider = aws.dr

  name       = "${var.project_name}-${var.environment}-dr-subnet-group"
  subnet_ids = var.dr_subnet_ids

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-dr-subnet-group"
  })
}

# Security Groups
resource "aws_security_group" "rds_primary" {
  provider = aws.primary

  name_prefix = "${var.project_name}-${var.environment}-rds-primary-"
  vpc_id      = var.primary_vpc_id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-rds-primary-sg"
  })
}

resource "aws_security_group" "rds_dr" {
  provider = aws.dr

  name_prefix = "${var.project_name}-${var.environment}-rds-dr-"
  vpc_id      = var.dr_vpc_id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.1.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-rds-dr-sg"
  })
}

# Primary RDS instance
resource "aws_db_instance" "primary" {
  provider = aws.primary

  identifier = "${var.project_name}-${var.environment}-primary"

  engine         = "mysql"
  engine_version = "8.0"
  instance_class = var.db_instance_class

  allocated_storage     = 20
  max_allocated_storage = 100
  storage_type          = "gp2"
  storage_encrypted     = true
  kms_key_id            = aws_kms_key.rds_primary.arn

  db_name  = var.db_name
  username = var.db_username
  password = random_password.db_password.result

  vpc_security_group_ids = [aws_security_group.rds_primary.id]
  db_subnet_group_name   = aws_db_subnet_group.primary.name

  backup_retention_period = 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"

  skip_final_snapshot = true
  deletion_protection = false

  enabled_cloudwatch_logs_exports = ["error", "general", "slow_query"]

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-primary-db"
  })
}

# Read replica in DR region
resource "aws_db_instance" "replica" {
  provider = aws.dr

  identifier = "${var.project_name}-${var.environment}-replica"

  replicate_source_db = aws_db_instance.primary.identifier

  instance_class = var.db_instance_class

  vpc_security_group_ids = [aws_security_group.rds_dr.id]

  skip_final_snapshot = true
  deletion_protection = false

  kms_key_id = aws_kms_key.rds_dr.arn

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-replica-db"
  })
}

# CloudWatch alarms for monitoring
resource "aws_cloudwatch_metric_alarm" "database_cpu" {
  provider = aws.primary

  alarm_name          = "${var.project_name}-${var.environment}-database-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = "120"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors RDS CPU utilization"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.primary.id
  }

  tags = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "database_connections" {
  provider = aws.primary

  alarm_name          = "${var.project_name}-${var.environment}-database-connections"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = "120"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors RDS connection count"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.primary.id
  }

  tags = local.common_tags
}