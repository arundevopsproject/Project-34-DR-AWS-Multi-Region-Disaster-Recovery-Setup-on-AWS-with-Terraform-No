#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Repository details
REPO_NAME="aws-multi-region-disaster-recovery"
REPO_DESCRIPTION="Multi-Region Disaster Recovery setup on AWS using Terraform with automated failover, cross-region replication, and comprehensive monitoring"

echo "🚀 GitHub Repository Creation Script"
echo "=================================="
echo

# Check if GitHub CLI is installed
if ! command -v gh &> /dev/null; then
    print_warning "GitHub CLI (gh) is not installed."
    print_info "You can install it with:"
    echo "  • Ubuntu/Debian: sudo apt install gh"
    echo "  • macOS: brew install gh"
    echo "  • Or download from: https://cli.github.com/"
    echo
    print_info "Alternatively, create the repository manually:"
    echo "1. Go to https://github.com/new"
    echo "2. Repository name: $REPO_NAME"
    echo "3. Description: $REPO_DESCRIPTION"
    echo "4. Make it public or private"
    echo "5. Don't initialize with README, .gitignore, or license"
    echo "6. Click 'Create repository'"
    echo
    print_info "Then run these commands to push:"
    echo "git remote add origin https://github.com/YOUR_USERNAME/$REPO_NAME.git"
    echo "git push -u origin main"
    exit 1
fi

# Check if user is logged in to GitHub
if ! gh auth status &> /dev/null; then
    print_error "You're not logged in to GitHub CLI."
    print_info "Please run: gh auth login"
    exit 1
fi

# Get GitHub username
GITHUB_USER=$(gh api user --jq .login)
print_status "GitHub user: $GITHUB_USER"

# Check if repository already exists
if gh repo view "$GITHUB_USER/$REPO_NAME" &> /dev/null; then
    print_warning "Repository $REPO_NAME already exists!"
    read -p "Do you want to push to the existing repository? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Operation cancelled."
        exit 0
    fi
else
    # Create the repository
    print_status "Creating GitHub repository..."
    
    read -p "Make repository public? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        VISIBILITY="--public"
    else
        VISIBILITY="--private"
    fi
    
    gh repo create "$REPO_NAME" \
        --description "$REPO_DESCRIPTION" \
        $VISIBILITY \
        --source=. \
        --push
    
    print_status "✅ Repository created and code pushed!"
fi

# Add remote if it doesn't exist
if ! git remote get-url origin &> /dev/null; then
    print_status "Adding GitHub remote..."
    git remote add origin "https://github.com/$GITHUB_USER/$REPO_NAME.git"
fi

# Push to GitHub
print_status "Pushing code to GitHub..."
git push -u origin main

# Set up repository settings
print_status "Setting up repository..."

# Add topics/tags
gh repo edit --add-topic terraform
gh repo edit --add-topic aws
gh repo edit --add-topic disaster-recovery
gh repo edit --add-topic infrastructure-as-code
gh repo edit --add-topic multi-region
gh repo edit --add-topic devops
gh repo edit --add-topic cloud

print_status "✅ Repository setup complete!"
echo
print_info "Repository URL: https://github.com/$GITHUB_USER/$REPO_NAME"
print_info "Clone URL: git clone https://github.com/$GITHUB_USER/$REPO_NAME.git"
echo
print_status "Next steps:"
echo "1. ⭐ Star the repository if you find it useful"
echo "2. 📝 Update terraform.tfvars with your values"
echo "3. 🚀 Deploy with: make setup"
echo "4. 📊 Monitor your infrastructure"
echo "5. 🔄 Test failover scenarios"