# Eon Cloud Account Provisioning

Terraform modules for provisioning cloud accounts to [Eon](https://eon.io) backup and restore service.

## Cloud Support Status

| Provider | Source Account | Restore Account |
|----------|----------------|-----------------|
| AWS | Available | Available |
| Azure | Planned | Planned |
| GCP | Planned | Planned |

## Directory Structure

```
.
├── aws/              # AWS module
├── azure/            # Azure module (planned)
├── gcp/              # GCP module (planned)
└── examples/
    └── aws/          # AWS usage example
```

## Quick Start (AWS)

```hcl
module "eon_aws" {
  source = "github.com/eon-io/eon-tf-infra-module//aws"

  eon_account_id      = "your-eon-account-uuid"
  scanning_account_id = "123456789012"  # Provided by Eon

  enable_source_account  = true
  enable_restore_account = true
}
```

See [`examples/aws/`](./examples/aws/) for a complete working example.

## Modules

### AWS (`./aws`)

Provisions AWS IAM roles and policies for Eon source and/or restore accounts.

**Source Account** creates:
- `EonSourceAccountRole` - Main role for Eon cross-account access
- `EonSourceAccountRoleBackupAccess` - Role for backup operations
- `EonSourceAccountRoleSendEventsToEon` - Role for S3 CDC events (optional)
- `EonSourceAccountRoleEKSAccess` - Role for EKS backups (optional)

**Restore Account** creates:
- `EonRestoreAccountRole` - Main role for Eon restore operations
- `EonRestoreNodeRole` - Role for EC2 restore nodes
- Instance profile for restore node attachment

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | ~> 5.0 |
| eon | ~> 2.0 |

## Security

- **External ID**: Uses Eon account UUID to prevent confused deputy attacks
- **Least Privilege**: Policies scoped to specific actions with tag conditions
- **Explicit Denies**: Direct S3/DynamoDB data access denied on source account main role

The IAM roles trust Eon's AWS accounts for cross-account access. The `scanning_account_id` parameter is provided by Eon during onboarding.

## License

See [LICENSE](LICENSE) for details.
