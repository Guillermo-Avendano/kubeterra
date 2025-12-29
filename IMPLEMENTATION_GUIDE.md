# Implementation Guide - Terraform Best Practices

This document describes the changes applied to the KubeTerra project to follow Terraform best practices.

## ✅ Changes Applied

### 1. **State and Secrets Protection** 

#### File: `.gitignore` (updated)
- ✅ Added protection for state files (`terraform.tfstate*`)
- ✅ Added protection for sensitive config files (`.env*`)
- ✅ Added protection for certificates and keys (`.key`, `.pem`, `.crt`)

**Verify:**
```bash
git status  # Verify that terraform.tfstate is not tracked
```

---

### 2. **Environment Variables instead of Hardcoded Values**

#### File: `05_terraform.sh` (updated)
**Changes:**
- ❌ Removed hardcoded passwords from script
- ❌ Removed hardcoded Mobius license
- ✅ Now uses environment variables: `${DOCKER_PASSWORD}`, `${MOBIUS_LICENSE}`, etc.
- ✅ Added validation of required variables
- ✅ Added configuration logging without exposing secrets

**Before:**
```bash
terraform apply \
  -var=var_docker_password='Yapeyu222#' \
  -var=var_mobius_license='01MOBIUS52464A...' \
```

**Now:**
```bash
terraform apply \
  -var=var_docker_password="${DOCKER_PASSWORD}" \
  -var=var_mobius_license="${MOBIUS_LICENSE}" \
```

---

### 3. **Environment Configuration File**

#### File: `.env.example` (created)
This is a template showing what environment variables are needed.

**Usage:**
```bash
# Copy the template
cp .env.example .env.local

# Edit with actual values
vim .env.local

# Load variables before running Terraform
source .env.local
./05_terraform.sh
```

**Content of `.env.local` (NEVER add to git):**
```bash
DOCKER_USERNAME=your_username
DOCKER_PASSWORD=your_password
MOBIUS_LICENSE=your_license
OPENAI_KEY=your_openai_key
```

---

### 4. **Organized Outputs**

#### File: `terra/kube/outputs.tf` (created)
Provides clear information about what was deployed:

**Run after `terraform apply`:**
```bash
terraform output  # See all outputs
terraform output deployment_summary  # See summary
terraform output kubernetes_configuration  # See K8s config
```

**Available outputs:**
- `deployment_summary` - Deployment summary
- `deployed_services` - Status of each service
- `kubernetes_configuration` - Kubernetes configuration
- `database_configuration` - Database configuration
- `image_registry_configuration` - Image registry URLs
- `image_versions` - Image versions
- `helm_charts` - Helm charts used
- `opensearch_configuration` - OpenSearch configuration
- And many more...

---

### 5. **Local Values for Reusability**

#### File: `terra/kube/locals.tf` (created)
Centralizes common values used in multiple places:

**Example of usage in resources:**
```terraform
# Instead of:
labels = {
  environment = var.var_environment
  team        = var.var_team
  created_by  = var.var_created_by
}

# Now you can use:
labels = local.common_labels
```

**Available local values:**
```terraform
local.namespace              # The main namespace
local.common_labels          # Common labels for all resources
local.docker_registry        # Docker registry URLs
local.image_versions         # Image versions
local.helm_charts            # Helm chart files
local.database               # Database configuration
local.storage                # Storage configuration
local.deployment_flags       # Deployment flags (deploy/skip)
```

---

### 6. **Variable Validations**

#### Files modified:
- `terra/kube/variables.tf` - Global variables
- `terra/kube/var-mobius.tf` - Mobius variables
- `terra/kube/var-mobiusview.tf` - Mobius View variables
- `terra/kube/var-opensearch.tf` - OpenSearch variables

**Added validations:**

| Variable | Validation |
|----------|-----------|
| `var_namespace_mobius` | Lowercase alphanumeric, max 63 characters |
| `var_database_provider` | Must be POSTGRESQL, SQLSERVER or ORACLE |
| `var_database_hostname` | Cannot be empty |
| `var_database_port` | Valid number between 1-65535 |
| `var_database_user` | Cannot be empty |
| `var_database_password` | Cannot be empty |
| `var_mobius_server_replica` | Between 1 and 10 |
| `var_mobius_view_replica` | Between 1 and 10 |
| `var_mobius_elastic_enabled` | YES or NO |
| `var_mobius_elastic_port` | Valid number between 1-65535 |
| `var_opensearch_host` | Cannot be empty |
| `var_opensearch_port` | Valid number between 1-65535 |
| `var_opensearch_user` | Cannot be empty |
| `var_opensearch_password` | Cannot be empty |

**Validations are executed automatically when you run `terraform plan` or `terraform apply`.**

---

## 🚀 How to Use the Changes

### Step 1: Prepare Environment
```bash
# Clone or navigate to the project
cd /path/to/kubeterra

# Create environment variables file
cp .env.example .env.local
vim .env.local  # Edit with actual values
```

### Step 2: Load Variables and Execute
```bash
# Load environment variables
source .env.local

# Change to Terraform directory
cd terra/kube

# Initialize Terraform
terraform init

# Plan the deployment
terraform plan -out=tfplan

# Apply the configuration
terraform apply tfplan

# See outputs
terraform output
```

### Step 3: Verify Deployment
```bash
# See specific outputs
terraform output deployment_summary
terraform output kubernetes_configuration

# Or see all:
terraform output
```

---

## 🔒 Security

### ✅ What is now protected:

1. **terraform.tfstate**
   - Contains infrastructure state and secrets
   - Now in `.gitignore`
   - ⚠️ **IMPORTANT**: Move to remote backend (S3, Azure, Kubernetes, etc.)

2. **Environment files**
   - Contain credentials and secrets
   - In `.gitignore`
   - Only exist locally

3. **Sensitive variables**
   - Marked with `sensitive = true`
   - Not shown in logs
   - Only passed via environment variables

4. **Validations**
   - Prevent invalid values
   - Fail early in `terraform plan`

### ⚠️ Recommended next security steps:

1. **Enable Remote State**
   ```terraform
   # terra/kube/backend.tf
   terraform {
     backend "kubernetes" {
       secret_suffix = "state"
       namespace     = "terraform"
     }
   }
   ```

2. **Use Secret Manager**
   - AWS Secrets Manager
   - Azure Key Vault
   - HashiCorp Vault
   - 1Password/LastPass

3. **CI/CD Integration**
   - GitHub Actions
   - GitLab CI
   - Jenkins
   - Azure DevOps

---

## 📋 Post-Implementation Checklist

- [ ] Run `git status` to confirm `.env.local` won't be committed
- [ ] Run `terraform init` in `terra/kube/`
- [ ] Run `terraform validate` to validate syntax
- [ ] Create `.env.local` based on `.env.example`
- [ ] Test `terraform plan` without changes
- [ ] Review that outputs are generated correctly
- [ ] Document environment-specific values
- [ ] Set up backup for Terraform state
- [ ] (Optional) Configure remote backend for state

---

## 📚 File Reference

| File | Change | Reason |
|------|--------|--------|
| `.gitignore` | Updated | Protect sensitive files |
| `05_terraform.sh` | Updated | Use environment variables |
| `.env.example` | Created | Configuration template |
| `terra/kube/outputs.tf` | Created | Clear deployment information |
| `terra/kube/locals.tf` | Created | Reusable values |
| `terra/kube/variables.tf` | Updated | Added validations |
| `terra/kube/var-mobius.tf` | Updated | Added validations |
| `terra/kube/var-mobiusview.tf` | Updated | Added validations |
| `terra/kube/var-opensearch.tf` | Updated | Added validations |

---

## 🔍 Validation of Changes

### Check Terraform syntax
```bash
cd terra/kube
terraform validate
```

### Check that outputs work
```bash
terraform output -json | jq .
```

### Simulate a plan
```bash
terraform plan
```

---

## ❓ Frequently Asked Questions

**Q: Do I need to commit `.env.local`?**
A: **NO**. The file `.env.local` is in `.gitignore`. Each developer should create it locally.

**Q: What happens if I forget environment variables?**
A: The script `05_terraform.sh` now validates that they exist and will fail with a clear message.

**Q: How can I use this in CI/CD?**
A: In your pipeline (GitHub Actions, GitLab CI, etc.), set the variables as secrets and source `.env.local` before running terraform.

**Q: What if I want to use `.tfvars` files instead of environment variables?**
A: You can use both. Precedence is still: CLI > tfvars > env vars > defaults.

---

## 📞 Support

For more information about specific changes:
- See `TERRAFORM_VARIABLE_PRECEDENCE.md` to understand variable precedence
- See configuration files for validation examples
- Consult Terraform documentation: https://www.terraform.io/

---

**Last updated:** December 29, 2025
**Version:** 1.0
