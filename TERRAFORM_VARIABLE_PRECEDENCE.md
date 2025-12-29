# Terraform Variable Precedence and Assignment Order

## Overview

This document describes the complete precedence order for variable assignment in the KubeTerra Terraform project. Understanding this hierarchy is crucial for managing configuration across multiple environments and deployment scenarios.

---

## Precedence Hierarchy (Highest to Lowest Priority)

### Level 1: Command-Line Arguments (HIGHEST PRIORITY)

**Description:** Variables passed directly via the `-var` flag during `terraform apply` execution.

**Characteristics:**
- Overrides all other variable sources
- Set at runtime during deployment
- Temporary and specific to that execution
- Most explicit and direct method

**Location:** [05_terraform.sh](05_terraform.sh)

**Example:**
```bash
terraform apply \
  -var=var_namespace_mobius='mobius' \
  -var=var_docker_username='gavendano@rs.com' \
  -var=var_docker_password='Yapeyu222#' \
  -var=var_pvc_storage_class='nfs-storage'
```

**When to use:**
- Secrets and sensitive data (passwords, API keys)
- Environment-specific overrides
- Temporary configuration changes
- CI/CD pipeline integrations

---

### Level 2: terraform.tfvars File

**Description:** Default values file that Terraform automatically loads.

**Characteristics:**
- Loaded automatically by Terraform
- Persisted in version control
- Easy to manage different configurations
- Can be environment-specific (terraform.prod.tfvars, terraform.dev.tfvars)

**Location:** [terra/kube/terraform.tfvars](terra/kube/terraform.tfvars)

**Example:**
```terraform
# Local Kubernetes cluster configuration
var_use_localkube = true
var_kubeconfig_path = "~/.kube/config"
var_namespace_mobius = "mobius"
var_pvc_storage_class = "nfs-client"

# Database configuration
var_database_hostname = "postgresql.shared-services.svc.cluster.local"
var_database_user = "postgres"
var_database_password = "mobius_123"

# Docker registry credentials
var_docker_username = "<To_be_updated>"
var_docker_password = "<To_be_updated>"
```

**When to use:**
- Default configuration values
- Environment-specific settings
- Values that change frequently
- Non-sensitive configuration data

---

### Level 3: Environment Variables (TF_VAR_* prefix)

**Description:** System environment variables prefixed with `TF_VAR_`.

**Characteristics:**
- Terraform automatically looks for `TF_VAR_<variable_name>` environment variables
- Useful for CI/CD pipelines
- Can be set in shell scripts or system configuration
- Useful for secrets management integrations

**Location:** [lib/env.sh](lib/env.sh)

**Example:**
```bash
export TF_VAR_namespace=mobius
export TF_VAR_docker_username=gavendano@rs.com
export TF_VAR_docker_password=Yapeyu222#
export TF_VAR_kube_source_registry=registry.rocketsoftware.com
```

**Note:** These must be sourced before running terraform commands:
```bash
source lib/env.sh
terraform apply
```

**When to use:**
- Secrets from secret management systems
- Build server environment variables
- Dynamic values from deployment pipelines
- Container-based deployments

---

### Level 4: Default Values in Variable Definition Files (LOWEST PRIORITY)

**Description:** Default values specified in Terraform variable declaration files.

**Characteristics:**
- Hardcoded in the configuration
- Serves as fallback values
- Documents expected variable types and descriptions
- Lowest priority - overridden by all other sources
- Part of the codebase and version controlled

**Locations:**

#### Global Variables
- [terra/kube/variables.tf](terra/kube/variables.tf) - Common variables (kubeconfig, namespaces, database settings)
- [terra/kube/variables-internal.tf](terra/kube/variables-internal.tf) - Internal variables not intended for modification

#### Service-Specific Variables
- [terra/kube/var-elasticsearch.tf](terra/kube/var-elasticsearch.tf) - Elasticsearch configuration
- [terra/kube/var-eventanalytics.tf](terra/kube/var-eventanalytics.tf) - Event Analytics configuration
- [terra/kube/var-mobius.tf](terra/kube/var-mobius.tf) - Mobius Server configuration
- [terra/kube/var-mobiusview.tf](terra/kube/var-mobiusview.tf) - Mobius View configuration
- [terra/kube/var-opensearch.tf](terra/kube/var-opensearch.tf) - OpenSearch configuration
- [terra/kube/var-smart-chat.tf](terra/kube/var-smart-chat.tf) - Smart Chat configuration

**Example from variables.tf:**
```terraform
variable "var_namespace_mobius" {
  description = "Namespace for mobius services"
  type        = string
  default     = "mobius"
}

variable "var_database_password" {
  description = "Database password"
  type        = string
  default     = "postgres"
  sensitive   = true
}
```

**When to use:**
- Project base configuration
- Reasonable default values
- Type validation and documentation
- Fallback for optional variables

---

## Visual Priority Ladder

```
╔═══════════════════════════════════════════════════════════════╗
║ LEVEL 1: CLI Arguments (-var)                    [WINS HERE]  ║
║ Example: terraform apply -var=password='secret'              ║
╠═══════════════════════════════════════════════════════════════╣
║ LEVEL 2: terraform.tfvars File                               ║
║ Example: var_password = "default_pass"                       ║
╠═══════════════════════════════════════════════════════════════╣
║ LEVEL 3: Environment Variables (TF_VAR_*)                    ║
║ Example: export TF_VAR_password="env_pass"                   ║
╠═══════════════════════════════════════════════════════════════╣
║ LEVEL 4: Default Values in *.tf Files            [LOSES HERE]║
║ Example: default = "hardcoded_pass"                          ║
╚═══════════════════════════════════════════════════════════════╝
```

---

## Resolution Algorithm

When Terraform evaluates a variable, it follows this resolution order:

1. **Check CLI arguments** (`-var`) → Found? **USE THIS VALUE**
2. **Check terraform.tfvars** → Found? **USE THIS VALUE**
3. **Check environment variables** (`TF_VAR_*`) → Found? **USE THIS VALUE**
4. **Check variable defaults** in `*.tf` files → Found? **USE THIS VALUE**
5. **No value found?** → Check if variable is required
   - If required: **ERROR - Must provide value**
   - If optional: **Use null or type default**

---

## Practical Example

Given this variable definition:

**File:** terra/kube/variables.tf
```terraform
variable "var_docker_password" {
  description = "Docker registry password"
  type        = string
  default     = "default_password"
  sensitive   = true
}
```

**Scenario 1: All sources defined**

```bash
# Level 4: Default in variables.tf
default = "default_password"

# Level 3: Environment variable
export TF_VAR_var_docker_password="env_password"

# Level 2: terraform.tfvars file
var_docker_password = "tfvars_password"

# Level 1: CLI argument
terraform apply -var=var_docker_password="cli_password"
```

**Result:** `var_docker_password = "cli_password"` ✅ (Level 1 wins)

---

**Scenario 2: Only levels 2 and 4 defined**

```bash
# Level 4: Default in variables.tf
default = "default_password"

# Level 2: terraform.tfvars file
var_docker_password = "tfvars_password"

# terraform apply (no -var argument)
```

**Result:** `var_docker_password = "tfvars_password"` ✅ (Level 2 wins)

---

**Scenario 3: Only level 4 defined**

```bash
# Level 4: Default in variables.tf
default = "default_password"

# terraform apply (no -var, no tfvars, no env var)
```

**Result:** `var_docker_password = "default_password"` ✅ (Level 4 as fallback)

---

## Best Practices

### Security Considerations

1. **Never hardcode secrets in .tf files** - Use CLI args or environment variables
2. **Exclude terraform.tfvars from version control if it contains secrets** - Add to .gitignore
3. **Use sensitive=true flag** for password variables (masks in logs)
4. **Integrate with secret management** systems (Vault, AWS Secrets Manager, etc.)

### Organization

1. **Use terraform.tfvars for non-sensitive defaults** - Easy to manage and version control
2. **Use CLI arguments for environment-specific overrides** - Explicit and auditable
3. **Use environment variables in CI/CD pipelines** - Integrates with automation
4. **Keep defaults in *.tf files minimal** - Only truly common values

### Maintainability

1. **Document expected values** in variable descriptions
2. **Use consistent naming conventions** (var_ prefix)
3. **Separate variables by component** (var-elasticsearch.tf, var-mobius.tf, etc.)
4. **Keep terraform.tfvars synchronized** with production values

---

## Project-Specific Configuration

### Current Setup in 05_terraform.sh

The deployment script uses Level 1 (CLI arguments) for critical values:

```bash
terraform apply \
  -var=var_namespace_mobius='mobius' \
  -var=var_docker_username='gavendano@rs.com' \
  -var=var_docker_password='Yapeyu222#' \
  -var=var_docker_email='gavendano@rs.com' \
  -var=var_mobius_license='01MOBIUS52464A...' \
  -var=var_smart_chat_openai_api_key=$OPENAI_KEY \
  -var=var_pvc_storage_class='nfs-storage'
```

### Current Setup in terraform.tfvars

Default configuration for local development:

```terraform
# Kubernetes configuration
var_use_localkube = true
var_kubeconfig_path = "~/.kube/config"
var_namespace_mobius = "mobius"
var_pvc_storage_class = "nfs-client"

# Database configuration
var_database_hostname = "postgresql.shared-services.svc.cluster.local"
var_database_port = "5432"
var_database_user = "postgres"
var_database_password = "mobius_123"

# Image registry URLs (for local registry)
var_mobiusserver_docker_artifactory_url = "localhost:5000/mobius-server"
var_mobiusview_docker_artifactory_url = "localhost:5000/mobius-view"
```

---

## Troubleshooting Variable Resolution Issues

### Problem: Variable has unexpected value

**Solution Steps:**
1. Check CLI arguments in terraform apply command (Level 1)
2. Check terraform.tfvars file (Level 2)
3. Check exported environment variables: `echo $TF_VAR_<variable_name>` (Level 3)
4. Check default value in *.tf file (Level 4)
5. Use `terraform console` to inspect actual variable value

### Problem: "Variable value required"

**Cause:** No value provided at any level and variable has no default

**Solution:** Provide value at one of the levels (preferably Level 1 or 2)

### Problem: Sensitive variable appears in logs

**Solution:** Ensure variable definition includes `sensitive = true`

---

## Summary Table

| Level | Source | Persistence | Use Case | Example |
|-------|--------|-------------|----------|---------|
| 1 | CLI `-var` | Temporary | Secrets, overrides | `-var=password='secret'` |
| 2 | terraform.tfvars | Persistent | Default config | `password = "default"` |
| 3 | TF_VAR_* env | Session-based | CI/CD, automation | `export TF_VAR_password` |
| 4 | *.tf defaults | Persistent | Fallback values | `default = "value"` |

---

## References

- [Terraform Official Documentation - Input Variables](https://www.terraform.io/language/values/variables)
- [Terraform Variables Precedence](https://www.terraform.io/language/values/variables#variable-definition-precedence)
- Project Structure: [README.md](README.md)
