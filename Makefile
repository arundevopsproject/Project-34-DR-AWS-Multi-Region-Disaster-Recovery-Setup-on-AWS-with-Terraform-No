# AWS Multi-Region Disaster Recovery - Makefile

.PHONY: help init plan apply destroy validate format clean check-aws

# Default target
help: ## Show this help message
	@echo "AWS Multi-Region Disaster Recovery - Available Commands:"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

# Prerequisites check
check-aws: ## Check if AWS CLI is configured
	@echo "Checking AWS CLI configuration..."
	@aws sts get-caller-identity > /dev/null || (echo "AWS CLI not configured. Run 'aws configure'" && exit 1)
	@echo "✓ AWS CLI is configured"

check-terraform: ## Check if Terraform is installed
	@echo "Checking Terraform installation..."
	@terraform version > /dev/null || (echo "Terraform not installed. Please install Terraform >= 1.0" && exit 1)
	@echo "✓ Terraform is installed"

check-docker: ## Check if Docker is installed
	@echo "Checking Docker installation..."
	@docker version > /dev/null || (echo "Docker not installed. Please install Docker" && exit 1)
	@echo "✓ Docker is installed"

check-deps: check-aws check-terraform check-docker ## Check all dependencies

# Terraform operations
init: check-deps ## Initialize Terraform
	@echo "Initializing Terraform..."
	@terraform init
	@echo "✓ Terraform initialized"

validate: ## Validate Terraform configuration
	@echo "Validating Terraform configuration..."
	@terraform validate
	@echo "✓ Configuration is valid"

format: ## Format Terraform files
	@echo "Formatting Terraform files..."
	@terraform fmt -recursive
	@echo "✓ Files formatted"

plan: init validate ## Create Terraform execution plan
	@echo "Creating Terraform plan..."
	@terraform plan -out=tfplan
	@echo "✓ Plan created (tfplan)"

apply: ## Apply Terraform configuration
	@echo "Applying Terraform configuration..."
	@if [ ! -f tfplan ]; then echo "No plan file found. Run 'make plan' first."; exit 1; fi
	@terraform apply tfplan
	@rm -f tfplan
	@echo "✓ Infrastructure deployed"

destroy: ## Destroy all resources
	@echo "⚠️  This will destroy ALL resources!"
	@read -p "Are you sure? Type 'yes' to continue: " confirm && [ "$$confirm" = "yes" ] || exit 1
	@terraform destroy
	@echo "✓ Infrastructure destroyed"

# Development helpers
clean: ## Clean temporary files
	@echo "Cleaning temporary files..."
	@rm -f tfplan
	@rm -f terraform.tfstate.backup
	@rm -rf .terraform/
	@echo "✓ Cleaned"

output: ## Show Terraform outputs
	@terraform output

# Docker operations
docker-build: ## Build the sample application Docker image
	@echo "Building Docker image..."
	@docker build -t aws-dr-app:latest .
	@echo "✓ Docker image built"

docker-run: ## Run the sample application locally
	@echo "Running application locally on port 8080..."
	@docker run -d -p 8080:80 --name aws-dr-app aws-dr-app:latest
	@echo "✓ Application running at http://localhost:8080"
	@echo "Health check: http://localhost:8080/health"

docker-stop: ## Stop the local application
	@docker stop aws-dr-app || true
	@docker rm aws-dr-app || true
	@echo "✓ Application stopped"

# Testing
test-health: ## Test application health endpoints
	@echo "Testing primary ALB health..."
	@curl -f $$(terraform output -raw primary_alb_dns_name)/health || echo "Primary health check failed"
	@echo "Testing DR ALB health..."
	@curl -f $$(terraform output -raw dr_alb_dns_name)/health || echo "DR health check failed"

# Security
security-scan: ## Run security scan on Terraform files
	@echo "Running security scan..."
	@if command -v tfsec > /dev/null; then \
		tfsec .; \
	else \
		echo "tfsec not installed. Install with: brew install tfsec"; \
	fi

# Cost estimation
cost-estimate: ## Estimate AWS costs (requires infracost)
	@echo "Estimating costs..."
	@if command -v infracost > /dev/null; then \
		infracost breakdown --path .; \
	else \
		echo "infracost not installed. Install from: https://www.infracost.io/docs/"; \
	fi

# Quick deployment
quick-deploy: check-deps format validate plan apply ## Quick deployment (format, validate, plan, apply)
	@echo "✓ Quick deployment completed"

# Full setup
setup: ## Complete setup from scratch
	@echo "Setting up AWS Multi-Region Disaster Recovery..."
	@if [ ! -f terraform.tfvars ]; then \
		echo "Creating terraform.tfvars from example..."; \
		cp terraform.tfvars.example terraform.tfvars; \
		echo "⚠️  Please edit terraform.tfvars with your values before continuing"; \
		exit 1; \
	fi
	@make quick-deploy
	@echo "✓ Setup completed successfully!"