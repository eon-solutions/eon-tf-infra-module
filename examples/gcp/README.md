# GCP Example

This example demonstrates how to use the Eon GCP module to provision source and restore account infrastructure.

## Prerequisites

1. GCP credentials configured (application default credentials or service account)
2. Eon account credentials (obtain from Eon console)
3. Eon account ID (UUID)
4. Control plane service account email (provided by Eon)
5. Scanning project ID (provided by Eon, for source accounts)
6. Terraform >= 1.3

## Usage

1. Copy the example variables file:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. Edit `terraform.tfvars` with your credentials:
   - Eon API credentials (client_id, client_secret, endpoint, project_id)
   - Eon account UUID
   - GCP project ID and region
   - Control plane service account (provided by Eon)
   - Scanning project ID (provided by Eon)

3. Initialize and apply:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

## What This Creates

### Source Account (for backups)
- Source service account for discovery operations
- Backup service account for data access
- Custom IAM roles with appropriate permissions
- Workload identity bindings for Eon control plane
- Registers the account as a source account in Eon

### Restore Account (for restores)
- Restore service account for restore operations
- Restore node service account for compute operations
- Custom IAM roles with appropriate permissions
- Workload identity bindings for Eon control plane
- Firestore database for command results
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

To scope to an organization or folder (source accounts only):
```hcl
organization_id = "123456789012"
folder_id       = "123456789012"  # Optional, requires organization_id
```

To use a Shared VPC host project (restore accounts only):
```hcl
host_project_id = "shared-vpc-host-project"
```

To customize feature permissions:
```hcl
enable_gcs      = true   # Google Cloud Storage
enable_gce      = true   # Google Compute Engine
enable_cloudsql = true   # Cloud SQL
enable_bigquery = true   # BigQuery
```

To disable automatic reconnection of existing disconnected accounts:
```hcl
reconnect_if_existing = false
```

## Automatic Reconnection

If an account was previously registered with Eon but is now disconnected (e.g., after running `terraform destroy` on the GCP infrastructure), running `terraform apply` will:

1. Detect the existing disconnected account in Eon
2. Recreate the GCP infrastructure (service accounts, roles, etc.)
3. Automatically reconnect the account via the Eon API

This behavior is enabled by default and can be disabled with `reconnect_if_existing = false`.

## Known Limitations

### Module Instantiation

The GCP external modules have `required_providers` blocks which means they cannot use Terraform's `count` or `for_each`. As a result, both source and restore infrastructure modules are always instantiated when the Eon GCP module is used. However, the Eon account registration is still conditional based on `enable_source_account` and `enable_restore_account`.

### IAM Propagation Delay

GCP IAM changes can take up to 60 seconds to propagate. The module includes a built-in delay to ensure IAM bindings (especially workload identity) are effective before Eon attempts to verify connectivity.

### Bucket Name Restrictions

If you encounter "bucket name restricted" errors during apply, this typically means bucket names were previously used and deleted in your project. GCS has a soft-delete retention period during which bucket names cannot be reused. To work around this, you can customize the `eon_restore_regions` variable to exclude affected regions:

```hcl
eon_restore_regions = [
  "us-central1", "us-east1", "europe-west1"
  # Add only the regions you need
]
```
