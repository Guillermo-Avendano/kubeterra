# Quick Start Guide - KubeTerra Best Practices Setup

## ⚡ Setup in 5 Minutes

### Step 1: Prepare Environment (1 minute)
```bash
cd /path/to/kubeterra

# Create environment variables file
cp .env.example .env.local

# Edit with your actual credentials
# On Windows: notepad .env.local
# On Linux/Mac: vim .env.local
```

### Step 2: Validate Configuration (2 minutes)
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

### Step 3: Plan Deployment (1 minute)
```bash
# See what will change
terraform plan -out=tfplan

# Review the plan (very important)
```

### Step 4: Apply Changes (1 minute)
```bash
# Run the deployment
terraform apply tfplan

# See results
terraform output deployment_summary
```

---

## 📋 Required Variables in .env.local

```bash
# Mandatory
DOCKER_USERNAME=your_username
DOCKER_PASSWORD=your_password
DOCKER_EMAIL=your_email@example.com
MOBIUS_LICENSE=your_license_key
PVC_STORAGE_CLASS=nfs-storage

# Optional but recommended
NAMESPACE=mobius
DATABASE_HOSTNAME=postgresql.shared-services.svc.cluster.local
DATABASE_USER=postgres
DATABASE_PASSWORD=your_db_password
OPENAI_KEY=your_openai_key  # Only if using Smart Chat
```

---

## ✅ Deployment Verification

```bash
# See all outputs
terraform output

# See Kubernetes configuration
terraform output kubernetes_configuration

# See deployed services
terraform output deployed_services

# See database information
terraform output database_configuration

# Verify pods in Kubernetes
kubectl get pods -n mobius
kubectl get svc -n mobius
kubectl get deployments -n mobius
```

---

## 🔐 Security - What You Should Know

✅ **Protected:**
- `.env.local` - In .gitignore (not uploaded to git)
- `terraform.tfstate` - In .gitignore (not uploaded to git)
- Sensitive variables - Marked as `sensitive = true`

⚠️ **IMPORTANT:**
- NEVER commit `.env.local`
- NEVER commit `terraform.tfstate`
- NEVER share your credentials
- Use a secret manager for production (AWS Secrets, Vault, etc)

---

## 🚨 Troubleshooting

### Error: "Required environment variable not set"
```bash
# Solution: Load environment variables
source .env.local
echo $DOCKER_USERNAME  # Verify that it was loaded
```

### Error: "Invalid value for var_database_port"
```bash
# Cause: The port is not valid
# Solution: Ensure DATABASE_PORT is a number between 1-65535
echo $DATABASE_PORT  # Check the value
```

### Error: "Namespace must be lowercase"
```bash
# Cause: The namespace has uppercase letters
# Solution: Use only lowercase
# Edit .env.local: NAMESPACE=mobius (not Mobius)
```

### Terraform state is corrupted
```bash
# Backup current state
cp terra/kube/terraform.tfstate terra/kube/terraform.tfstate.backup

# Refresh state
cd terra/kube
terraform refresh
```

---

## 📊 Automated Validations

The following validations are executed automatically:

```bash
✓ Namespace: lowercase alphanumeric, max 63 characters
✓ Database Port: valid number 1-65535
✓ Database Provider: POSTGRESQL, SQLSERVER or ORACLE
✓ Replicas: number between 1-10
✓ Elasticsearch Port: valid number 1-65535
✓ OpenSearch Port: valid number 1-65535
```

If there's an error in the validations, `terraform plan` will fail with a clear message.

---

## 💡 Useful Tips

### See detailed logs
```bash
# DEBUG level
export TF_LOG=DEBUG
terraform plan
```

### Save plan for review
```bash
terraform plan -out=tfplan
# Review
terraform show tfplan
# Apply after
terraform apply tfplan
```

### Destroy only one resource
```bash
terraform destroy -target='kubernetes_namespace.mobius'
```

### See changes without applying
```bash
terraform plan -json | jq .
```

---

## 📞 Useful Commands

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

---

## 🔄 Typical Workflow

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

## 📚 Related Documentation

- [TERRAFORM_VARIABLE_PRECEDENCE.md](TERRAFORM_VARIABLE_PRECEDENCE.md) - Understand variable precedence
- [IMPLEMENTATION_GUIDE.md](IMPLEMENTATION_GUIDE.md) - Detailed implementation guide
- [terra/kube/readme.MD](terra/kube/readme.MD) - Kubernetes specific documentation

---

**Questions? Check the documentation files or run `terraform validate` to verify your configuration.**
