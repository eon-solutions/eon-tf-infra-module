# AWS Example

This example demonstrates how to use the Eon AWS module to provision source and restore account infrastructure.

## Prerequisites

1. AWS CLI configured with credentials
2. Eon account credentials (obtain from Eon console)
3. Terraform >= 1.0

## Usage

1. Copy the example variables file:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. Edit `terraform.tfvars` with your credentials:
   - AWS region and profile
   - Eon API credentials (client_id, client_secret, endpoint, project_id)
   - Eon account UUID
   - Eon scanning account ID (provided by Eon)

3. Initialize and apply:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

## What This Creates

### Source Account (for backups)
- `EonSourceAccountRole` - Main role for Eon cross-account access
- `EonSourceAccountRoleBackupAccess` - Role for backup operations
- `EonSourceAccountRoleSendEventsToEon` - Role for S3 CDC events
- `EonSourceAccountRoleEKSAccess` - Role for EKS backups
- Registers the account as a source account in Eon

### Restore Account (for restores)
- `EonRestoreAccountRole` - Main role for Eon restore operations
- `EonRestoreNodeRole` - Role for EC2 restore nodes
- Instance profile for restore node attachment
- Registers the account as a restore account in Eon

## Customization

To provision only a source account:
```hcl
enable_source_account  = true
enable_restore_account = false
```

To provision only a restore account:
```hcl
enable_source_account  = false
enable_restore_account = true
```

To use an explicit AWS account ID instead of caller identity:
```hcl
aws_account_id = "123456789012"
```
