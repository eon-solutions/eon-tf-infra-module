# Eon Cloud Account Provisioning

Terraform modules for provisioning cloud accounts to [Eon](https://eon.io) backup and restore service.

## Cloud Support Status

| Provider | Source Account | Restore Account |
|----------|----------------|-----------------|
| AWS | Available | Available |
| Azure | Available | Available |
| GCP | Available | Available |

## Directory Structure

```
.
├── aws/              # AWS module
├── azure/            # Azure module
├── gcp/              # GCP module
└── examples/
    ├── aws/          # AWS usage example
    ├── azure/        # Azure usage example
    └── gcp/          # GCP usage example
```

## Quick Start

### AWS

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    eon = {
      source  = "eon-io/eon"
      version = "~> 2.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

provider "eon" {
  client_id     = var.eon_client_id
  client_secret = var.eon_client_secret
  endpoint      = var.eon_endpoint
  project_id    = var.eon_project_id
}

module "eon_aws" {
  source = "github.com/eon-solutions/eon-tf-infra-module//aws"

  # Required: Pass providers explicitly
  providers = {
    aws = aws
    eon = eon
  }

  eon_account_id      = "your-eon-account-uuid"
  eon_endpoint        = "https://api.eon.io"
  eon_client_id       = "your-client-id"
  eon_client_secret   = "your-client-secret"
  eon_project_id      = "your-project-id"
  scanning_account_id = "123456789012"  # Provided by Eon

  enable_source_account  = true
  enable_restore_account = true
}
```

See [`examples/aws/`](./examples/aws/) for a complete working example.

### Azure

```hcl
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.83, < 4.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.0"
    }
    eon = {
      source  = "eon-io/eon"
      version = "~> 2.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

provider "azuread" {}

provider "eon" {
  client_id     = var.eon_client_id
  client_secret = var.eon_client_secret
  endpoint      = var.eon_endpoint
  project_id    = var.eon_project_id
}

module "eon_azure" {
  source = "github.com/eon-solutions/eon-tf-infra-module//azure"

  # Required: Pass providers explicitly
  providers = {
    azurerm = azurerm
    azuread = azuread
    eon     = eon
  }

  # Eon API configuration
  eon_endpoint      = "https://api.eon.io"
  eon_client_id     = "your-client-id"
  eon_client_secret = "your-client-secret"
  eon_project_id    = "your-project-id"

  # Azure configuration
  tenant_id       = "your-azure-tenant-id"
  subscription_id = "your-azure-subscription-id"

  # App IDs (provided by Eon during onboarding)
  management_app_id     = "eon-management-app-id"
  backup_app_id         = "eon-backup-app-id"
  backup_restore_app_id = "eon-backup-restore-app-id"

  enable_source_account  = true
  enable_restore_account = true
}
```

See [`examples/azure/`](./examples/azure/) for a complete working example.

### GCP

```hcl
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.0"
    }
    eon = {
      source  = "eon-io/eon"
      version = "~> 2.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.gcp_region
}

provider "eon" {
  client_id     = var.eon_client_id
  client_secret = var.eon_client_secret
  endpoint      = var.eon_endpoint
  project_id    = var.eon_project_id
}

module "eon_gcp" {
  source = "github.com/eon-solutions/eon-tf-infra-module//gcp"

  # Required: Pass providers explicitly
  providers = {
    google = google
    eon    = eon
  }

  # Eon API configuration
  eon_endpoint      = "https://api.eon.io"
  eon_client_id     = "your-client-id"
  eon_client_secret = "your-client-secret"
  eon_project_id    = "your-eon-project-id"
  eon_account_id    = "your-eon-account-uuid"

  # GCP configuration
  project_id                    = "your-gcp-project-id"
  control_plane_service_account = "eon-control@eon-project.iam.gserviceaccount.com"
  scanning_project_id           = "eon-scanning-project"  # Provided by Eon

  enable_source_account  = true
  enable_restore_account = true
}
```

See [`examples/gcp/`](./examples/gcp/) for a complete working example.

## Provider Configuration

All modules require explicit provider configuration using the `providers` block. This is necessary because the modules use `configuration_aliases` to support flexible provider configurations.

### Why Explicit Providers?

1. **Multi-account deployments**: You can provision multiple accounts by passing different provider configurations to separate module instances
2. **Provider aliasing**: Supports scenarios where you need to use aliased providers (e.g., different AWS regions)
3. **Terraform best practices**: Explicit provider passing makes dependencies clear and prevents implicit provider inheritance issues

### Required Providers by Module

| Module | Required Providers |
|--------|-------------------|
| AWS | `aws`, `eon` |
| Azure | `azurerm`, `azuread`, `eon` |
| GCP | `google`, `eon` |

### Multi-Account Example (AWS)

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    eon = {
      source  = "eon-io/eon"
      version = "~> 2.0"
    }
  }
}

provider "aws" {
  alias   = "production"
  region  = "us-east-1"
  profile = "production"
}

provider "aws" {
  alias   = "staging"
  region  = "us-west-2"
  profile = "staging"
}

provider "eon" {
  client_id     = var.eon_client_id
  client_secret = var.eon_client_secret
  endpoint      = var.eon_endpoint
  project_id    = var.eon_project_id
}

module "eon_aws_production" {
  source = "github.com/eon-solutions/eon-tf-infra-module//aws"

  providers = {
    aws = aws.production
    eon = eon
  }

  # ... configuration
}

module "eon_aws_staging" {
  source = "github.com/eon-solutions/eon-tf-infra-module//aws"

  providers = {
    aws = aws.staging
    eon = eon
  }

  # ... configuration
}
```

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

### Azure (`./azure`)

Provisions Azure custom roles and role assignments for Eon source and/or restore accounts.

**Source Account** creates:
- `EonSourceManagementRole` - Custom role for resource discovery and management
- `EonSourceBackupRole` - Custom role for backup data access
- `eon-source-internal-rg` - Resource group for Eon internal resources
- Role assignments for Eon service principals

**Restore Account** creates:
- `EonRestoreManagementRole` - Custom role for restore infrastructure management
- `EonRestoreBackupRole` - Custom role for restore data access
- `EonRestoreOperationsRole` - Custom role for storage operations
- `EonRestoreRole` - Custom role for VM and disk operations
- `eon-restore-{id}` - Resource group for Eon restore operations
- Role assignments for Eon service principals

### GCP (`./gcp`)

Provisions GCP service accounts and IAM roles for Eon source and/or restore accounts.

**Source Account** creates:
- Source service account for discovery operations
- Backup service account for data access
- Custom IAM roles with appropriate permissions
- Workload identity bindings for Eon control plane

**Restore Account** creates:
- Restore service account for restore operations
- Restore node service account for compute operations
- Custom IAM roles with appropriate permissions
- Workload identity bindings for Eon control plane

## Common Features

### Automatic Reconnection

All modules support automatic reconnection of existing accounts. If an account was previously registered with Eon but is now disconnected (e.g., after running `terraform destroy` on the cloud infrastructure), running `terraform apply` will:

1. Detect the existing disconnected account in Eon
2. Recreate the cloud infrastructure (roles, permissions, etc.)
3. Automatically reconnect the account via the Eon API

This behavior is controlled by the `reconnect_if_existing` variable (default: `true`).

```hcl
module "eon_aws" {
  # ...

  # Set to false to skip automatic reconnection
  reconnect_if_existing = false
}
```

### Idempotent Operations

All modules are idempotent:
- Running `terraform apply` multiple times produces the same result
- Existing accounts are detected and reused (not duplicated)
- Infrastructure changes are applied incrementally

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | ~> 5.0 (for AWS module) |
| azurerm | >= 3.83, < 4.0 (for Azure module) |
| azuread | ~> 2.0 (for Azure module) |
| google | >= 4.0 (for GCP module) |
| eon | ~> 2.0 |

## Security

### AWS
- **External ID**: Uses Eon account UUID to prevent confused deputy attacks
- **Least Privilege**: Policies scoped to specific actions with tag conditions
- **Explicit Denies**: Direct S3/DynamoDB data access denied on source account main role

### Azure
- **Service Principals**: Uses Azure AD app registrations with federated credentials
- **Custom Roles**: Minimal permissions scoped to subscription level
- **Resource Groups**: Dedicated resource groups for Eon internal operations

### GCP
- **Workload Identity**: Uses GCP Workload Identity for secure cross-project access
- **Service Accounts**: Dedicated service accounts with minimal permissions
- **External ID**: Uses Eon account UUID for confused deputy protection
- **IAM Propagation**: Includes built-in delay for IAM binding propagation

## License

See [LICENSE](LICENSE) for details.
