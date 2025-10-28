# Project-33-AWS-Multi-Region-Disaster-Recovery-Setup-on-AWS-with-Terraform-No

https://dev.to/copubah/building-a-multi-region-disaster-recovery-setup-on-aws-with-terraform-l69




[![GitHub](https://img.shields.io/badge/GitHub-Repository-blue?logo=github)](https://github.com/Copubah/aws-multi-region-disaster-recovery)
[![Terraform](https://img.shields.io/badge/Terraform-%3E%3D1.0-623CE4?logo=terraform)](https://www.terraform.io/)
[![AWS](https://img.shields.io/badge/AWS-Multi--Region-FF9900?logo=amazon-aws)](https://aws.amazon.com/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](https://opensource.org/licenses/MIT)

This Terraform configuration sets up a multi-region disaster recovery infrastructure on AWS with the following components:

## Clone Repository

```bash
# Clone the repository
git clone https://github.com/Copubah/aws-multi-region-disaster-recovery.git
cd aws-multi-region-disaster-recovery

# Quick setup
make setup
```

## Architecture Overview

- Primary Region: us-east-1
- DR Region: eu-west-1

```
                                    ┌─────────────────────────────────────┐
                                    │            Route 53                 │
                                    │     DNS Failover & Health Check     │
                                    │                                     │
                                    │  Primary ──failover──> Secondary   │
                                    └─────────────┬───────────────────────┘
                                                  │
                        ┌─────────────────────────┼─────────────────────────┐
                        │                         │                         │
                        ▼                         ▼                         │
            ┌─────────────────────────┐ ┌─────────────────────────┐         │
            │     PRIMARY REGION      │ │       DR REGION         │         │
            │      (us-east-1)        │ │      (eu-west-1)        │         │
            │                         │ │                         │         │
            │  ┌─────────────────────┐│ │┌─────────────────────┐  │         │
            │  │        VPC          ││ ││        VPC          │  │         │
            │  │   10.0.0.0/16       ││ ││   10.1.0.0/16       │  │         │
            │  │                     ││ ││                     │  │         │
            │  │  ┌───────────────┐  ││ ││  ┌───────────────┐  │  │         │
            │  │  │ Public Subnet │  ││ ││  │ Public Subnet │  │  │         │
            │  │  │               │  ││ ││  │               │  │  │         │
            │  │  │ ┌───────────┐ │  ││ ││  │ ┌───────────┐ │  │  │         │
            │  │  │ │    ALB    │ │  ││ ││  │ │    ALB    │ │  │  │         │
            │  │  │ └───────────┘ │  ││ ││  │ └───────────┘ │  │  │         │
            │  │  └───────────────┘  ││ ││  └───────────────┘  │  │         │
            │  │                     ││ ││                     │  │         │
            │  │  ┌───────────────┐  ││ ││  ┌───────────────┐  │  │         │
            │  │  │Private Subnet │  ││ ││  │Private Subnet │  │  │         │
            │  │  │               │  ││ ││  │               │  │  │         │
            │  │  │ ┌───────────┐ │  ││ ││  │ ┌───────────┐ │  │  │         │
            │  │  │ │ECS Fargate│ │  ││ ││  │ │ECS Fargate│ │  │  │         │
            │  │  │ │ (2 tasks) │ │  ││ ││  │ │ (2 tasks) │ │  │  │         │
            │  │  │ └───────────┘ │  ││ ││  │ └───────────┘ │  │  │         │
            │  │  │               │  ││ ││  │               │  │  │         │
            │  │  │ ┌───────────┐ │  ││ ││  │               │  │  │         │
            │  │  │ │    RDS    │ │  ││ ││  │               │  │  │         │
            │  │  │ │ (Primary) │ │  ││ ││  │               │  │  │         │
            │  │  │ └───────────┘ │  ││ ││  │               │  │  │         │
            │  │  └───────────────┘  ││ ││  └───────────────┘  │  │         │
            │  └─────────────────────┘│ │└─────────────────────┘  │         │
            └─────────────────────────┘ └─────────────────────────┘         │
                        │                           │                       │
                        │                           │                       │
            ┌─────────────────────────┐ ┌─────────────────────────┐         │
            │         S3 Bucket       │ │         S3 Bucket       │         │
            │        (Primary)        │ │        (Replica)        │         │
            │                         │ │                         │         │
            │    Cross-Region         │ │                         │         │
            │    Replication ─────────┼─┼────────────────────────▶│         │
            │                         │ │                         │         │
            └─────────────────────────┘ └─────────────────────────┘         │
                                                    │                       │
                                                    │                       │
                                        ┌─────────────────────────┐         │
                                        │      RDS Read Replica   │         │
                                        │       (Standby)         │         │
                                        │                         │         │
                                        │   ◀─── Replication      │         │
                                        │        from Primary     │         │
                                        └─────────────────────────┘         │
                                                                            │
                        ┌───────────────────────────────────────────────────┘
                        │
                        ▼
            ┌─────────────────────────────────────┐
            │         Monitoring & Security       │
            │                                     │
            │  • CloudWatch Logs & Metrics       │
            │  • KMS Encryption (Multi-Region)   │
            │  • IAM Roles (Least Privilege)     │
            │  • VPC Flow Logs                   │
            │  • Auto Scaling Policies           │
            │  • Health Check Alarms             │
            └─────────────────────────────────────┘
```

### Data Flow & Failover Process

1. Normal Operation: Traffic routes to Primary Region (us-east-1)
2. Health Check: Route 53 monitors primary ALB health every 30 seconds
3. Failure Detection: If 3 consecutive health checks fail, Route 53 triggers failover
4. Automatic Failover: DNS routes traffic to DR Region (eu-west-1)
5. Data Consistency: S3 replication ensures data availability, RDS replica provides read access

## Components

### Core Infrastructure
- VPC with public/private subnets in each region
- Internet Gateway and NAT Gateway for connectivity
- Security Groups with least privilege access

### Storage & Database
- S3 buckets with cross-region replication
- RDS primary database in us-east-1
- RDS read replica in eu-west-1
- Automated backups and encryption

### Application Layer
- Application Load Balancer in each region
- ECS Fargate service for containerized applications
- Auto Scaling configuration

### DNS & Failover
- Route 53 hosted zone
- Health checks for primary region
- Automatic failover to DR region

### Security
- IAM roles with least privilege principles
- KMS encryption for all resources
- VPC Flow Logs for monitoring

## Prerequisites

1. AWS CLI configured with appropriate permissions
2. Terraform >= 1.0
3. Docker (for building container images)

## Deployment

### Option 1: Using Makefile (Recommended)
```bash
# Clone the repository
git clone https://github.com/Copubah/aws-multi-region-disaster-recovery.git
cd aws-multi-region-disaster-recovery

# Complete setup
make setup
```

### Option 2: Manual Terraform Commands
1. Initialize Terraform:
```bash
terraform init
```

2. Plan the deployment:
```bash
terraform plan
```

3. Apply the configuration:
```bash
terraform apply
```

## Configuration

Update `terraform.tfvars` with your specific values:

```hcl
project_name = "your-project"
environment = "prod"
domain_name = "your-domain.com"
```

## Disaster Recovery Testing

The setup includes automated failover capabilities. To test:

1. Monitor Route 53 health checks in AWS Console
2. Simulate primary region failure
3. Verify traffic routes to DR region
4. Test application functionality in DR region

## Cost Optimization

- RDS read replica can be stopped when not needed
- ECS services scale to zero when no traffic
- S3 Intelligent Tiering for cost optimization

## Security Considerations

- All data encrypted at rest and in transit
- IAM roles follow least privilege principle
- VPC endpoints for secure AWS service access
- Security groups restrict access to necessary ports only

## Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Repository

- GitHub: https://github.com/Copubah/aws-multi-region-disaster-recovery
- Issues: https://github.com/Copubah/aws-multi-region-disaster-recovery/issues
- Discussions: https://github.com/Copubah/aws-multi-region-disaster-recovery/discussions

## Support

If you find this project helpful, please consider giving it a star on GitHub!
