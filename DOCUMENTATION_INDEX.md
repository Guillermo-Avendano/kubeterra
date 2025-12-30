# KubeTerra Complete Documentation Index

**Last Updated:** December 30, 2025  
**Version:** 1.0

---

## Table of Contents

1. [Getting Started](#1-getting-started)
2. [Quick Start Guide](#2-quick-start-guide)
3. [Variable Management](#3-variable-management)
4. [Terraform Execution](#4-terraform-execution)
5. [File Structure and References](#5-file-structure-and-references)
6. [Troubleshooting](#6-troubleshooting)
7. [Additional Resources](#7-additional-resources)

---

---

## 1. Getting Started

**[↑ Back to Index](#table-of-contents)**

### 1.1 What is KubeTerra?

KubeTerra is a comprehensive Infrastructure-as-Code (IaC) solution that uses Terraform to deploy and manage a complete Kubernetes-based application stack including:

- **Mobius Server** - Core application framework
- **Mobius View** - Web interface and visualization
- **Event Analytics** - Real-time event processing and analysis
- **Smart Chat** - AI-powered chat functionality with OpenAI integration
- **Supporting Services:**
  - PostgreSQL database
  - Elasticsearch/OpenSearch for search and indexing
  - Kafka for event streaming
  - Nginx for load balancing
  - Persistent storage with PVCs

### 1.2 Prerequisites

Before you begin, ensure you have:

- **Kubernetes Cluster** - Accessible and configured
- **Tools Installed:**
  - `terraform` (v1.0+)
  - `kubectl` (compatible with your cluster version)
  - `helm` (v3+)
  - `bash` shell (for script execution)
  - `git` (for cloning the repository)

- **Credentials and Licenses:**
  - Docker registry credentials (for pulling images)
  - Mobius license key
  - OpenAI API key (optional, for Smart Chat)
  - Database credentials

### 1.3 Project Structure Overview

```
kubeterra/
├── 00_install_wsl.cmd          # Windows WSL installation script
├── 01_install_docker.sh         # Docker installation script
├── 02_install_helm_kubectl.sh   # Helm and kubectl installation
├── 03_install_rancher_terraform.sh  # Rancher and Terraform installation
├── 04_pullimages.sh             # Pre-pull container images
├── 05_terraform.sh              # Main Terraform deployment script
├── .env.example                 # Environment configuration template
├── .env.local                   # Your configuration (not in version control)
├── README.md                    # Project overview
├── QUICK_START.md               # Quick start guide
├── TERRAFORM_VARIABLE_PRECEDENCE.md  # Variable priority documentation
├── TERRAFORM_EXECUTION_SEQUENCE.md   # Execution flow documentation
├── IMPLEMENTATION_GUIDE.md      # Detailed implementation guide
│
├── terra/                       # Terraform root directory
│   └── kube/                    # Kubernetes Terraform configuration
│       ├── provider.tf          # Provider configuration
│       ├── variables.tf         # Input variables definition
│       ├── variables-internal.tf # Internal variables
│       ├── locals.tf            # Computed local values
│       ├── terraform.tfvars     # Variable values
│       ├── outputs.tf           # Output values
│       │
│       ├── rsc-*.tf             # Resource files (secrets, configmaps, etc.)
│       ├── svc-*.tf             # Service deployment files (databases, etc.)
│       ├── app-*.tf             # Application deployment files
│       │
│       └── readme.MD            # Kubernetes-specific documentation
│
├── lib/                         # Helper scripts
│   ├── common.sh                # Common functions
│   ├── certificates.sh          # Certificate generation
│   ├── kubefunctions.sh         # Kubernetes utilities
│   ├── registry.sh              # Registry management
│   └── ...
│
├── conf/                        # Configuration files
│   ├── images.csv               # Docker image list
│   ├── ingress.csv              # Ingress configuration
│   └── templates/               # Configuration templates
│
└── doc/                         # Additional documentation

```

---

---

**[↑ Back to Index](#table-of-contents)**

## 2. Quick Start Guide

### 2.1 Setup in 5 Minutes

#### Step 1: Prepare Environment (1 minute)

```bash
cd /path/to/kubeterra

# Create environment variables file
cp .env.example .env.local

# Edit with your actual credentials
# On Windows: notepad .env.local
# On Linux/Mac: vim .env.local
```

#### Step 2: Validate Configuration (2 minutes)

```bash
# Load environment variables
source .env.local

# Verify that variables were loaded
echo "Docker User: $DOCKER_USERNAME"
echo "Namespace: $NAMESPACE"

# Change to Terraform directory
cd terra/kube

# Validate Terraform syntax
terraform validate
```

#### Step 3: Plan Deployment (1 minute)

```bash
# See what will change
terraform plan -out=tfplan

# Review the plan (very important)
```

#### Step 4: Apply Changes (1 minute)

```bash
# Run the deployment
terraform apply tfplan

# See results
terraform output deployment_summary
```

### 2.2 Required Variables in .env.local

**Mandatory Variables:**

```bash
DOCKER_USERNAME=your_username
DOCKER_PASSWORD=your_password
DOCKER_EMAIL=your_email@example.com
MOBIUS_LICENSE=your_license_key
PVC_STORAGE_CLASS=nfs-storage
PVC_STORAGE_CAPACITY=100Gi
```

**Optional but Recommended:**

```bash
NAMESPACE=mobius
DATABASE_HOSTNAME=postgresql.shared-services.svc.cluster.local
DATABASE_USER=postgres
DATABASE_PASSWORD=your_db_password
OPENAI_KEY=your_openai_key  # Only if using Smart Chat
TF_LOG=DEBUG                 # For detailed troubleshooting
```

### 2.3 Deployment Verification

```bash
# See all outputs
terraform output

# See Kubernetes configuration
terraform output kubernetes_configuration

# See deployed services
terraform output deployed_services

# Verify pods in Kubernetes
kubectl get pods -n mobius
kubectl get svc -n mobius
kubectl get deployments -n mobius
```

### 2.4 Security Best Practices

✅ **Protected:**
- `.env.local` - In .gitignore (not uploaded to git)
- `terraform.tfstate` - In .gitignore (not uploaded to git)
- Sensitive variables - Marked as `sensitive = true`

⚠️ **IMPORTANT:**
- **NEVER commit `.env.local`** to version control
- **NEVER commit `terraform.tfstate`** to version control
- **NEVER share your credentials** publicly
- Use a secret manager for production (AWS Secrets, Vault, etc)

### 2.5 Useful Tips

#### See detailed logs
```bash
# DEBUG level logging
export TF_LOG=DEBUG
terraform plan
```

#### Save plan for review
```bash
terraform plan -out=tfplan
# Review
terraform show tfplan
# Apply after
terraform apply tfplan
```

#### Destroy only one resource
```bash
terraform destroy -target='kubernetes_namespace.mobius'
```

#### See changes without applying
```bash
terraform plan -json | jq .
```

### 2.6 Useful Commands

```bash
# Deployment information
terraform output deployment_summary

# Force state update
terraform refresh

# See defined variables
terraform console
> var.var_namespace_mobius

# Import existing resources
terraform import kubernetes_namespace.mobius mobius

# Clean local state (be careful)
rm -rf terra/kube/.terraform
terraform init
```

### 2.7 Typical Workflow

```bash
# 1. Make changes in .env.local or Terraform code
vim .env.local
vim terra/kube/variables.tf

# 2. Load variables
source .env.local

# 3. Review changes
cd terra/kube
terraform plan

# 4. If everything looks good, apply
terraform apply -auto-approve

# 5. Verify results
terraform output
kubectl get all -n mobius
```

---

---

**[↑ Back to Index](#table-of-contents)**

## 3. Variable Management

### 3.1 Variable Precedence (Priority Order)

Terraform evaluates variables in this **strict priority order** (highest to lowest):

#### Level 1: Command-Line Arguments (HIGHEST PRIORITY)
```bash
terraform apply -var=var_namespace='mobius'
```

#### Level 2: terraform.tfvars File
```terraform
var_namespace = "mobius"
```

#### Level 3: Environment Variables (TF_VAR_* prefix)
```bash
export TF_VAR_var_namespace="mobius"
```

#### Level 4: Default Values in *.tf Files (LOWEST PRIORITY)
```terraform
variable "var_namespace" {
  default = "mobius"
}
```

### 3.2 Variable Priority Visual

```
╔═══════════════════════════════════════════════════════════════╗
║ LEVEL 1: CLI Arguments (-var)                    [WINS HERE]  ║
║ Example: terraform apply -var=password='secret'              ║
╠═══════════════════════════════════════════════════════════════╣
║ LEVEL 2: terraform.tfvars File                               ║
║ Example: password = "default_pass"                           ║
╠═══════════════════════════════════════════════════════════════╣
║ LEVEL 3: Environment Variables (TF_VAR_*)                    ║
║ Example: export TF_VAR_password="env_pass"                   ║
╠═══════════════════════════════════════════════════════════════╣
║ LEVEL 4: Default Values in *.tf Files            [LOSES HERE]║
║ Example: default = "hardcoded_pass"                          ║
╚═══════════════════════════════════════════════════════════════╝
```

### 3.3 Variable Resolution Algorithm

When Terraform evaluates a variable, it follows this process:

1. **Check CLI arguments** (`-var`) → Found? **USE THIS VALUE**
2. **Check terraform.tfvars** → Found? **USE THIS VALUE**
3. **Check environment variables** (`TF_VAR_*`) → Found? **USE THIS VALUE**
4. **Check variable defaults** in `*.tf` files → Found? **USE THIS VALUE**
5. **No value found?** → Check if variable is required
   - If required: **ERROR - Must provide value**
   - If optional: **Use null or type default**

### 3.4 Complete Variable Reference

#### Required Variables (must be set)

| Variable | Purpose | Type | Example |
|----------|---------|------|---------|
| `DOCKER_USERNAME` | Docker registry username | string | `user@company.com` |
| `DOCKER_PASSWORD` | Docker registry password | string | `secure_password` |
| `DOCKER_EMAIL` | Docker registry email | string | `user@company.com` |
| `MOBIUS_LICENSE` | Mobius product license | string | `01MOBIUS...` |
| `PVC_STORAGE_CLASS` | Kubernetes storage class | string | `nfs-storage` |
| `PVC_STORAGE_CAPACITY` | Storage volume capacity | string | `100Gi` |

#### Optional Variables

| Variable | Purpose | Type | Example | Default |
|----------|---------|------|---------|---------|
| `NAMESPACE` | Kubernetes namespace | string | `mobius` | `mobius` |
| `KUBECONFIG_PATH` | Path to kubeconfig | string | `~/.kube/config` | `~/.kube/config` |
| `DATABASE_HOSTNAME` | Database server | string | `pg.local.svc` | varies |
| `DATABASE_USER` | Database user | string | `postgres` | `postgres` |
| `DATABASE_PASSWORD` | Database password | string | `secure_pass` | varies |
| `DATABASE_PORT` | Database port | number | `5432` | `5432` |
| `OPENAI_KEY` | OpenAI API key | string | `sk-...` | `` (empty) |
| `TF_LOG` | Terraform logging level | string | `DEBUG` | `` (none) |

#### Advanced Options

| Variable | Purpose | Default |
|----------|---------|---------|
| `VAR_USE_LOCALKUBE` | Use local cluster | `false` |
| `VAR_DEPLOY_POSTGRESQL` | Deploy PostgreSQL in cluster | `true` |
| `VAR_OPENSEARCH_USER` | OpenSearch admin user | `admin` |
| `VAR_OPENSEARCH_PASSWORD` | OpenSearch password | (random) |
| `VAR_MOBIUS_SERVER_IMAGE` | Mobius server version | `12.5.2` |
| `VAR_MOBIUS_VIEW_IMAGE` | Mobius view version | `12.5.2` |
| `VAR_EVENT_ANALYTICS_IMAGE` | Event Analytics version | `2.0.9` |
| `VAR_SMART_CHAT_IMAGE` | Smart Chat version | `1.2.8` |

### 3.5 Practical Variable Examples

#### Example 1: All sources defined

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

#### Example 2: Only levels 2 and 4 defined

```bash
# Level 4: Default in variables.tf
default = "default_password"

# Level 2: terraform.tfvars file
var_docker_password = "tfvars_password"

# terraform apply (no -var argument)
```

**Result:** `var_docker_password = "tfvars_password"` ✅ (Level 2 wins)

#### Example 3: Only level 4 defined

```bash
# Level 4: Default in variables.tf
default = "default_password"

# terraform apply (no -var, no tfvars, no env var)
```

**Result:** `var_docker_password = "default_password"` ✅ (Level 4 as fallback)

### 3.6 Best Practices for Variables

**Security:**
- Never hardcode secrets in .tf files
- Use CLI arguments for sensitive data
- Mark sensitive variables with `sensitive = true`
- Integrate with secret management systems

**Organization:**
- Use terraform.tfvars for non-sensitive defaults
- Use CLI arguments for environment-specific overrides
- Use environment variables in CI/CD pipelines
- Keep defaults in *.tf files minimal

**Maintainability:**
- Document expected values in descriptions
- Use consistent naming conventions (var_ prefix)
- Separate variables by component
- Keep terraform.tfvars synchronized

---

**[↑ Back to Index](#table-of-contents)**

---

## 4. Terraform Execution

### 4.1 Terraform Apply Execution Flow

When you run `terraform apply`, Terraform follows this **8-step sequence**:

#### Step 1: Validation and Reading
- Validates the syntax of all `.tf` files
- Reads the Terraform configuration in the current directory
- Loads variable values from `.tfvars` files, environment variables, etc.

#### Step 2: Initialization (if necessary)
- Verifies the `.terraform` directory
- If not initialized, performs `terraform init` actions automatically

#### Step 3: Read Current State
- Reads the `terraform.tfstate` file (previous state)
- Compares the current state with the desired configuration

#### Step 4: Plan (Implicit)
- If no previous plan exists, generates one automatically
- Determines which resources will be created, modified, or deleted
- Displays the plan on screen for your review

#### Step 5: User Confirmation
- Prompts: `Do you want to perform these actions?`
- You must type `yes` to continue (or use `-auto-approve` flag to skip this)

#### Step 6: Applying Changes
- Executes operations in parallel based on dependencies
- Creates, modifies, or deletes resources in the correct order
- Updates Terraform's internal state

#### Step 7: State Update
- Saves the new state to `terraform.tfstate`
- Creates a backup in `terraform.tfstate.backup`

#### Step 8: Outputs
- Calculates and displays output values defined in the configuration
- Stores them for future reference

### 4.2 Terraform File Execution Sequence

**IMPORTANT:** Terraform **DOES NOT execute files in a specific order by filename**. All `.tf` files in the directory are read and processed **simultaneously**, but Terraform respects **dependencies between resources**.

However, in your project structure, the **logical conceptual order** is:

#### Phase 1: Base Configuration (conceptually loaded first)
1. **`variables.tf`** - Defines all input variables
2. **`variables-internal.tf`** - Additional internal variables
3. **`var-*.tf`** - Service-specific variables (elasticsearch, eventanalytics, etc.)
4. **`locals.tf`** - Computed local values based on variables
5. **`provider.tf`** - Provider configuration (Kubernetes, Helm)

#### Phase 2: Base Resources (no dependencies)
6. **`rsc-rbac.tf`** - RBAC policies, ServiceAccounts
7. **`rsc-service-account.tf`** - Service accounts
8. **`rsc-secret.tf`** - Secrets (credentials)
9. **`rsc-configmap.tf`** - ConfigMaps (configurations)
10. **`rsc-pvc.tf`** - PersistentVolumeClaims (storage)
11. **`rsc-route.tf`** - Routes/Ingress

#### Phase 3: Infrastructure Services
12. **`svc-postgres.tf`** - PostgreSQL database
13. **`svc-external-postgres.tf`** - External PostgreSQL
14. **`svc-elasticsearch.tf`** - Elasticsearch service
15. **`svc-opensearch.tf`** - OpenSearch service
16. **`svc-opensearch-dashboard.tf`** - OpenSearch Dashboard
17. **`svc-kafka.tf`** - Kafka message broker
18. **`svc-internal-nginx.tf`** - Internal Nginx
19. **`svc-helm-chart-download.tf`** - Helm chart downloads

#### Phase 4: Applications (depend on Phase 3)
20. **`app-smart-chat.tf`** - Smart Chat application
21. **`app-smart-chat-indexing-proxy.tf`** - Smart Chat Indexing Proxy
22. **`app-eventanalytics.tf`** - Event Analytics application
23. **`app-mobius.tf`** - Mobius application
24. **`app-mobiusview.tf`** - Mobius View application

#### Phase 5: Outputs
25. **`outputs.tf`** - Output values

### 4.3 Actual Execution Behavior

In reality, Terraform builds a DAG (Directed Acyclic Graph) of dependencies and executes resources **in parallel** when they do not depend on each other.

**Key Points:**
- **Parallel execution:** Resources with no interdependencies are created simultaneously
- **Dependency tracking:** Terraform automatically determines the correct order based on resource references
- **Performance:** Parallelization speeds up infrastructure provisioning
- **State management:** Each resource's state is tracked independently

**Dependency Examples:**
- `app-*.tf` files depend on `svc-*.tf` files being created first
- `svc-*.tf` files depend on `rsc-*.tf` files (secrets, configmaps, PVCs)
- All resources depend on provider configuration in `provider.tf`
- All computation depends on variables defined in `variables.tf` and `locals.tf`

### 4.4 Script Execution: 05_terraform.sh

The main automation script that orchestrates the entire Terraform deployment process.

#### Functions:

1. **Environment Setup**
   - Sets up directory paths (`CORE_SCRIPTS_DIR`, `TERRA_DIR`)
   - Sources common helper scripts from `lib/common.sh`

2. **Environment Variables Loading**
   - Loads configuration from `.env.local` file
   - Validates that `.env.local` exists (exits with error if missing)
   - Makes all environment variables available to Terraform

3. **Kubernetes Namespace Creation**
   - Checks if the Mobius namespace exists
   - Creates it if it doesn't exist
   - Skips creation if namespace is already present

4. **Helm Repository Setup**
   - Adds OpenSearch Helm repository
   - Updates all Helm repositories to get latest charts

5. **Terraform Initialization**
   - Runs `terraform init` to download providers
   - Sets executable permissions on provider binaries
   - Ensures `.terraform/providers/` is properly configured

6. **Validation**
   - Verifies all required environment variables are set:
     - `DOCKER_USERNAME` - Docker registry username
     - `DOCKER_PASSWORD` - Docker registry password
     - `DOCKER_EMAIL` - Docker registry email
     - `MOBIUS_LICENSE` - Mobius license key
     - `PVC_STORAGE_CLASS` - Kubernetes storage class
     - `PVC_STORAGE_CAPACITY` - Storage volume capacity
   - Exits with error if any required variable is missing

7. **Terraform Apply**
   - Passes environment variables as Terraform input variables
   - Uses `-auto-approve` flag to skip manual confirmation
   - Logs output to `terraform.log` file
   - Validates success/failure and provides appropriate error messages

#### Usage:
```bash
./05_terraform.sh
```

#### Prerequisites:
- `.env.local` file must exist and be configured
- Kubernetes cluster must be accessible
- `kubectl` and `helm` must be installed
- Terraform must be installed

### 4.5 .env.local and .env.example Configuration Files

#### `.env.local` - Your Deployment Configuration

**Purpose:** Contains all environment variables required for **your specific deployment**.

**Creation:**
```bash
cp .env.example .env.local
# Edit .env.local with your actual values
```

**Required Variables:**

| Variable | Purpose | Example |
|----------|---------|---------|
| `DOCKER_USERNAME` | Docker registry username | `myuser` |
| `DOCKER_PASSWORD` | Docker registry password | `mypassword123` |
| `DOCKER_EMAIL` | Docker registry email | `user@example.com` |
| `MOBIUS_LICENSE` | Mobius product license key | `LICENSE_KEY_HERE` |
| `PVC_STORAGE_CLASS` | Kubernetes storage class name | `nfs-storage` |
| `PVC_STORAGE_CAPACITY` | Storage volume capacity | `100Gi` |

**Optional Variables:**

| Variable | Purpose | Example |
|----------|---------|---------|
| `OPENAI_KEY` | OpenAI API key for Smart Chat | `sk-...` |
| `NAMESPACE` | Kubernetes namespace | `mobius` |
| `KUBECONFIG_PATH` | Path to kubeconfig file | `~/.kube/config` |
| `KUBE_SOURCE_REGISTRY` | Source registry for images | `registry.rocketsoftware.com` |
| `LOCAL_REGISTRY_PORT` | Local registry port | `5000` |
| `DATABASE_HOSTNAME` | Database host | `postgresql.svc.cluster.local` |
| `DATABASE_USER` | Database username | `postgres` |
| `DATABASE_PASSWORD` | Database password | `securepassword` |
| `DATABASE_PORT` | Database port | `5432` |
| `TF_LOG` | Terraform logging level | `DEBUG` |

**Advanced Options:**

| Variable | Purpose | Example |
|----------|---------|---------|
| `VAR_USE_LOCALKUBE` | Use local Kubernetes cluster | `false` |
| `VAR_DEPLOY_POSTGRESQL` | Deploy PostgreSQL in cluster | `true` |
| `VAR_OPENSEARCH_USER` | OpenSearch username | `admin` |
| `VAR_OPENSEARCH_PASSWORD` | OpenSearch password | `password` |
| `VAR_MOBIUS_SERVER_IMAGE` | Mobius server image version | `12.5.2` |
| `VAR_MOBIUS_VIEW_IMAGE` | Mobius view image version | `12.5.2` |
| `VAR_EVENT_ANALYTICS_IMAGE` | Event Analytics image version | `2.0.9` |
| `VAR_SMART_CHAT_IMAGE` | Smart Chat image version | `1.2.8` |

#### `.env.example` - Template for Configuration

**Purpose:** Template file showing all available configuration options with example values.

**Usage:**
1. Copy to `.env.local`
2. Edit with your actual values
3. Never modify `.env.example` for your deployment

**Security Considerations:**
- **NEVER commit `.env.local` to version control** (add to `.gitignore`)
- **NEVER share `.env.local` publicly** (contains sensitive credentials)
- Keep `.env.local` file with restricted permissions: `chmod 600 .env.local`
- Use a secrets management system in production environments
- Consider using separate `.env.local` files for different environments (dev, staging, prod)

#### Configuration Workflow:

1. Copy template file:
   ```bash
   cp .env.example .env.local
   ```

2. Edit with your configuration:
   ```bash
   nano .env.local  # or your preferred editor
   ```

3. Verify configuration is complete:
   ```bash
   source .env.local
   echo $DOCKER_USERNAME  # Should display your username
   ```

4. Run deployment script:
   ```bash
   ./05_terraform.sh
   ```

### 4.6 Integration Flow Diagram

```
┌─────────────────────┐
│   .env.example      │ (template)
└──────────┬──────────┘
           │ (copy and configure)
           ▼
┌─────────────────────┐
│   .env.local        │ (your configuration with secrets)
└──────────┬──────────┘
           │ (source)
           ▼
┌──────────────────────────────────────┐
│     05_terraform.sh                  │
│ ┌──────────────────────────────────┐ │
│ │ 1. Load .env.local variables     │ │
│ │ 2. Create Kubernetes namespace   │ │
│ │ 3. Setup Helm repositories       │ │
│ │ 4. Initialize Terraform          │ │
│ │ 5. Validate required variables   │ │
│ │ 6. Run terraform apply           │ │
│ └──────────────────────────────────┘ │
└──────────┬───────────────────────────┘
           │
           ▼
┌──────────────────────────────────────┐
│      Terraform Execution              │
│ (terra/kube/*.tf files)              │
│                                       │
│ Variables → Locals → Resources       │
│ Services → Applications → Outputs    │
└──────────┬───────────────────────────┘
           │
           ▼
┌──────────────────────────────────────┐
│   Kubernetes Cluster                 │
│ (Namespaces, Pods, Services, etc.)  │
└──────────────────────────────────────┘
```

**[↑ Back to Index](#-table-of-contents)**

---

---

## 5. File Structure and References

### 5.1 Complete File Reference Guide

#### Deployment Script Files
| File | Purpose |
|------|---------|
| `05_terraform.sh` | Main orchestration script for Terraform deployment |
| `.env.example` | Template for environment configuration |
| `.env.local` | User configuration with sensitive credentials (not in version control) |

#### Configuration Files
| File | Purpose | Location |
|------|---------|----------|
| `variables.tf` | Core input variables shared across all resources | `terra/kube/` |
| `variables-internal.tf` | Internal variables not exposed as inputs | `terra/kube/` |
| `var-*.tf` | Service-specific variables (elasticsearch, kafka, postgres, etc.) | `terra/kube/` |
| `locals.tf` | Computed values derived from variables | `terra/kube/` |
| `terraform.tfvars` | Variable values for current deployment | `terra/kube/` |

#### Provider Files
| File | Purpose | Location |
|------|---------|----------|
| `provider.tf` | Kubernetes and Helm provider configuration | `terra/kube/` |

#### Resource Files
| File | Purpose | Location |
|------|---------|----------|
| `rsc-rbac.tf` | Role-Based Access Control resources | `terra/kube/` |
| `rsc-service-account.tf` | Kubernetes service accounts | `terra/kube/` |
| `rsc-secret.tf` | Kubernetes secrets for credentials | `terra/kube/` |
| `rsc-configmap.tf` | Kubernetes configuration maps | `terra/kube/` |
| `rsc-pvc.tf` | Persistent volume claims for storage | `terra/kube/` |
| `rsc-route.tf` | Ingress and routes | `terra/kube/` |

#### Service Deployment Files
| File | Purpose | Location |
|------|---------|----------|
| `svc-postgres.tf` | PostgreSQL database deployment | `terra/kube/` |
| `svc-external-postgres.tf` | External PostgreSQL configuration | `terra/kube/` |
| `svc-elasticsearch.tf` | Elasticsearch deployment | `terra/kube/` |
| `svc-opensearch.tf` | OpenSearch deployment | `terra/kube/` |
| `svc-opensearch-dashboard.tf` | OpenSearch Dashboard | `terra/kube/` |
| `svc-kafka.tf` | Apache Kafka deployment | `terra/kube/` |
| `svc-internal-nginx.tf` | Internal Nginx web server | `terra/kube/` |
| `svc-helm-chart-download.tf` | Helm chart repository setup | `terra/kube/` |

#### Application Deployment Files
| File | Purpose | Location |
|------|---------|----------|
| `app-smart-chat.tf` | Smart Chat application deployment | `terra/kube/` |
| `app-smart-chat-indexing-proxy.tf` | Smart Chat indexing proxy | `terra/kube/` |
| `app-eventanalytics.tf` | Event Analytics application | `terra/kube/` |
| `app-mobius.tf` | Mobius application | `terra/kube/` |
| `app-mobiusview.tf` | Mobius View application | `terra/kube/` |

#### Output and Documentation Files
| File | Purpose | Location |
|------|---------|----------|
| `outputs.tf` | Output values exposed after deployment | `terra/kube/` |
| `readme.MD` | Kubernetes-specific documentation | `terra/kube/` |

#### Helper Scripts
| File | Purpose | Location |
|------|---------|----------|
| `common.sh` | Common functions and utilities | `lib/` |
| `certificates.sh` | Certificate generation functions | `lib/` |
| `kubefunctions.sh` | Kubernetes utility functions | `lib/` |
| `registry.sh` | Container registry functions | `lib/` |
| `get_helm.sh` | Helm installation script | `lib/` |
| `ingress.sh` | Ingress configuration functions | `lib/` |

#### Installation Scripts
| File | Purpose |
|------|---------|
| `00_install_wsl.cmd` | Windows WSL installation script |
| `01_install_docker.sh` | Docker installation script |
| `02_install_helm_kubectl.sh` | Helm and kubectl installation |
| `03_install_rancher_terraform.sh` | Rancher and Terraform installation |
| `04_pullimages.sh` | Pre-pull container images |

#### Configuration and Documentation
| File | Purpose |
|------|---------|
| `conf/images.csv` | Docker image list and versions |
| `conf/ingress.csv` | Ingress routing configuration |
| `conf/templates/` | Configuration templates |
| `README.md` | Project overview and introduction |
| `QUICK_START.md` | Quick start guide |
| `TERRAFORM_VARIABLE_PRECEDENCE.md` | Variable priority documentation |
| `TERRAFORM_EXECUTION_SEQUENCE.md` | Execution flow documentation |
| `IMPLEMENTATION_GUIDE.md` | Detailed implementation guide |
| `DOCUMENTATION_INDEX.md` | This file - complete documentation index |

### 5.2 Variable File Dependencies

```
variables.tf (defines all input variables)
        ↓
var-*.tf (service-specific variables)
        ↓
locals.tf (computed values from variables)
        ↓
provider.tf (uses locals for configuration)
        ↓
rsc-*.tf (resource definitions, uses locals)
        ↓
svc-*.tf (service deployments, uses rsc-* resources)
        ↓
app-*.tf (application deployments, uses svc-* resources)
        ↓
outputs.tf (exposes deployment information)
```

**[↑ Back to Index](#table-of-contents)**

---

---

## 6. Troubleshooting

### 6.1 Common Error Messages

#### Error: "Required environment variable not set"

**Cause:** One of the required variables is missing from `.env.local`

**Solution:**
```bash
# Load environment variables
source .env.local

# Verify that each variable is set
echo "Docker User: $DOCKER_USERNAME"
echo "Docker Pass: $DOCKER_PASSWORD"
echo "Docker Email: $DOCKER_EMAIL"
echo "Mobius License: $MOBIUS_LICENSE"
echo "PVC Storage Class: $PVC_STORAGE_CLASS"
echo "PVC Storage Capacity: $PVC_STORAGE_CAPACITY"
```

#### Error: "Invalid value for var_database_port"

**Cause:** The port is not a valid number

**Solution:**
```bash
# Verify DATABASE_PORT is a number between 1-65535
echo $DATABASE_PORT
# Edit .env.local if needed
```

#### Error: "Namespace must be lowercase"

**Cause:** The namespace has uppercase letters

**Solution:**
```bash
# Edit .env.local
# Change: NAMESPACE=Mobius
# To: NAMESPACE=mobius
```

#### Error: "Terraform state is corrupted"

**Cause:** State file has inconsistencies

**Solution:**
```bash
# Backup current state
cp terra/kube/terraform.tfstate terra/kube/terraform.tfstate.backup

# Refresh state
cd terra/kube
terraform refresh
```

#### Error: ".env.local not found"

**Cause:** File doesn't exist

**Solution:**
```bash
# Create from template
cp .env.example .env.local

# Edit with your values
vim .env.local

# Verify it was created
ls -la .env.local
```

### 6.2 Debugging Techniques

#### Enable Debug Logging

```bash
# Set before running terraform
export TF_LOG=DEBUG

# Run terraform command
terraform plan

# Optionally save to file
export TF_LOG_PATH=terraform-debug.log
```

#### Validate Configuration

```bash
# Check Terraform syntax
terraform validate

# Check variable values
terraform console
> var.var_namespace_mobius
> var.var_docker_username

# Press Ctrl+D to exit console
```

#### Check State

```bash
# View current state
terraform show

# List resources in state
terraform state list

# Show specific resource
terraform state show kubernetes_namespace.mobius
```

#### Test Variables

```bash
# Test variable precedence
source .env.local

# Check environment variable
echo $TF_VAR_var_namespace

# Check in terraform.tfvars
grep var_namespace terra/kube/terraform.tfvars
```

### 6.3 Automated Validations

The following validations are executed automatically during `terraform plan`:

```bash
✓ Namespace: lowercase alphanumeric, max 63 characters
✓ Database Port: valid number 1-65535
✓ Database Provider: POSTGRESQL, SQLSERVER or ORACLE
✓ Replicas: number between 1-10
✓ Elasticsearch Port: valid number 1-65535
✓ OpenSearch Port: valid number 1-65535
```

If there's an error in the validations, `terraform plan` will fail with a clear message.

### 6.4 Common Workflow Issues

#### Issue: Changes not being applied

```bash
# Solution: Run plan first to see what changes
terraform plan

# Then explicitly apply
terraform apply
```

#### Issue: State and actual infrastructure out of sync

```bash
# Solution: Refresh state
terraform refresh

# Then check what changed
terraform plan
```

#### Issue: Want to destroy and recreate

```bash
# Option 1: Destroy entire deployment
terraform destroy

# Option 2: Destroy only one resource
terraform destroy -target='kubernetes_namespace.mobius'

# Option 3: Remove from state without destroying
terraform state rm 'kubernetes_namespace.mobius'
**[↑ Back to Index](#-table-of-contents)**

```

---

---

## 7. Additional Resources

### 7.1 Related Documentation Files

Inside the KubeTerra project:

- **[README.md](README.md)** - Project overview and introduction
- **[QUICK_START.md](QUICK_START.md)** - Quick start guide (also in section 2)
- **[TERRAFORM_VARIABLE_PRECEDENCE.md](TERRAFORM_VARIABLE_PRECEDENCE.md)** - Detailed variable precedence (also in section 3)
- **[TERRAFORM_EXECUTION_SEQUENCE.md](TERRAFORM_EXECUTION_SEQUENCE.md)** - Execution sequence details (also in section 4)
- **[IMPLEMENTATION_GUIDE.md](IMPLEMENTATION_GUIDE.md)** - Detailed implementation procedures

### 7.2 External Resources

#### Official Documentation
- [Terraform Official Documentation](https://www.terraform.io/docs)
- [Terraform Input Variables](https://www.terraform.io/language/values/variables)
- [Terraform Variable Precedence](https://www.terraform.io/language/values/variables#variable-definition-precedence)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Helm Documentation](https://helm.sh/docs/)

#### Learning Resources
- [Terraform Learn - Get Started](https://learn.hashicorp.com/collections/terraform/aws-get-started)
- [Kubernetes Basics](https://kubernetes.io/docs/tutorials/kubernetes-basics/)
- [Helm Charts Best Practices](https://helm.sh/docs/chart_best_practices/)

### 7.3 Getting Help

1. **Check the documentation** - Start with this index
2. **Review error messages** - They usually indicate the problem
3. **Enable debug logging** - `export TF_LOG=DEBUG`
4. **Check Terraform state** - `terraform show`
5. **Review variable values** - `terraform console`
6. **Check Kubernetes status** - `kubectl describe <resource>`

### 7.4 Best Practices Summary

#### Planning
- Always run `terraform plan` before `terraform apply`
- Review all proposed changes carefully
- Use named plans: `terraform plan -out=tfplan`

#### Deployment
- Use `.env.local` for sensitive data
- Keep backups of `terraform.tfstate`
- Use version control for all `.tf` files
- Document any manual changes

#### Security
- Never commit `.env.local` to git
- Use `sensitive = true` for passwords
- Rotate credentials regularly
- Use secret management systems in production

#### Maintenance
- Keep Terraform and providers updated
- Monitor resource utilization
- Plan for scaling early
- Document infrastructure changes

---

---

## Summary

This documentation provides a complete guide to deploying and managing the KubeTerra infrastructure-as-code project. It covers:

1. ✅ Initial setup and prerequisites
2. ✅ Quick start procedures (5 minutes)
3. ✅ Variable management and precedence
4. ✅ Terraform execution sequence
5. ✅ Complete file structure reference
6. ✅ Troubleshooting guide
7. ✅ Additional resources

**For quick start:** Jump to [Section 2](#2-quick-start-guide)

**For variables:** See [Section 3](#3-variable-management)

**For troubleshooting:** See [Section 6](#6-troubleshooting)

---

**Questions? Check the relevant section or enable DEBUG logging with `export TF_LOG=DEBUG`**

---

*Last Updated: December 30, 2025*  
*KubeTerra Documentation Version 1.0*
