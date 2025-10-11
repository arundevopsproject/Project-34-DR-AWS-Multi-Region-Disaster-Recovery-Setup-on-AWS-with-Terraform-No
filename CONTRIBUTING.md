# Contributing to AWS Multi-Region Disaster Recovery

Thank you for your interest in contributing to this project! This document provides guidelines for contributing to the AWS Multi-Region Disaster Recovery setup.

## Getting Started

1. Fork the repository
2. Clone your fork locally
3. Create a new branch for your feature or bug fix
4. Make your changes
5. Test your changes thoroughly
6. Submit a pull request

## Development Setup

### Prerequisites
- Terraform >= 1.0
- AWS CLI >= 2.0
- Docker >= 20.0
- Git >= 2.0

### Local Development
1. Copy the example configuration:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. Update `terraform.tfvars` with your test values

3. Initialize Terraform:
   ```bash
   terraform init
   ```

4. Validate your changes:
   ```bash
   terraform validate
   terraform plan
   ```

## Code Standards

### Terraform Code Style
- Use consistent indentation (2 spaces)
- Follow Terraform naming conventions
- Add comments for complex logic
- Use meaningful resource names
- Include appropriate tags on all resources

### Module Structure
- Keep modules focused and reusable
- Include proper variable descriptions
- Provide comprehensive outputs
- Add validation rules where appropriate

### Documentation
- Update README.md for significant changes
- Document new variables and outputs
- Include examples for new features
- Update architecture diagrams if needed

## Testing

### Pre-commit Checks
Before submitting a PR, ensure:
- [ ] `terraform fmt` has been run
- [ ] `terraform validate` passes
- [ ] All modules have proper documentation
- [ ] No sensitive data is committed
- [ ] .gitignore is updated if needed

### Testing Infrastructure
- Test in a separate AWS account/region
- Verify all resources are created correctly
- Test failover scenarios
- Validate monitoring and alerting
- Confirm proper cleanup with destroy script

## Pull Request Process

1. **Branch Naming**: Use descriptive branch names
   - `feature/add-monitoring`
   - `fix/rds-security-group`
   - `docs/update-readme`

2. **Commit Messages**: Use clear, descriptive commit messages
   ```
   feat: add CloudWatch dashboard for monitoring
   
   - Add comprehensive dashboard for all services
   - Include custom metrics for application health
   - Update documentation with dashboard screenshots
   ```

3. **PR Description**: Include:
   - What changes were made
   - Why the changes were necessary
   - How to test the changes
   - Any breaking changes
   - Screenshots (if applicable)

4. **Review Process**:
   - All PRs require review
   - Address feedback promptly
   - Keep PRs focused and reasonably sized

## Types of Contributions

### Bug Fixes
- Fix security vulnerabilities
- Resolve resource configuration issues
- Correct documentation errors

### Features
- Add new AWS services integration
- Enhance monitoring capabilities
- Improve automation scripts
- Add cost optimization features

### Documentation
- Improve setup instructions
- Add troubleshooting guides
- Create video tutorials
- Update architecture diagrams

### Infrastructure Improvements
- Optimize resource configurations
- Enhance security posture
- Improve performance
- Add compliance features

## Security Guidelines

- Never commit sensitive data (passwords, keys, etc.)
- Use AWS Secrets Manager for sensitive values
- Follow AWS security best practices
- Implement least privilege access
- Enable encryption for all data

## Questions and Support

- Open an issue for bugs or feature requests
- Use discussions for questions and ideas
- Tag maintainers for urgent issues
- Provide detailed information when reporting issues

## Code of Conduct

- Be respectful and inclusive
- Focus on constructive feedback
- Help others learn and grow
- Maintain a professional tone

## License

By contributing, you agree that your contributions will be licensed under the same license as the project.