#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning "This will destroy ALL resources created by Terraform!"
print_warning "This action cannot be undone!"
echo

read -p "Are you sure you want to destroy all resources? Type 'destroy' to confirm: " confirm
if [ "$confirm" != "destroy" ]; then
    print_status "Destruction cancelled"
    exit 0
fi

print_status "Planning destruction..."
terraform plan -destroy -out=destroy-plan

echo
read -p "Proceed with destruction? (yes/no): " final_confirm
if [ "$final_confirm" != "yes" ]; then
    print_warning "Destruction cancelled"
    rm -f destroy-plan
    exit 0
fi

print_status "Destroying infrastructure..."
terraform apply destroy-plan

# Clean up plan file
rm -f destroy-plan

print_status "All resources have been destroyed!"