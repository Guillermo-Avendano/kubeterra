# Mobius Stack Deployment on Kubernetes using Terraform

This guide walks you through deploying the **Mobius Stack**, including **Smart Chat**, on an Kubernetes cluster using Terraform.

---

## 🧰 Prerequisites

Before starting, ensure you have:

- Access to this Git repository
- A Docker-compatible environment
- Access credentials to the private Docker registry (for downloading the Terraform image)
- Access to Kubernetes cluster (Local Kube or Rancher) with appropriate permissions to your namespace
- Necessary details like image and helm chart versions needed for your stack
- Access to an external database and its connection endpoint (if using external DB)
- **Optional**: Support for deploying PostgreSQL within the cluster (handled by Terraform)
---

## 📦 Setup Instructions

### 1. Clone the Repository

Open a Ubuntu terminal and run:

```bash
mkdir -p cd /mnt/c/Projects/Mobius/
cd /mnt/c/Projects/Mobius/
git clone <repo>
```

> Replace `<repo>` with the actual Git repository URL.

---

### 2. Update Configuration

Before running Terraform, update the `terraform.tfvars` file with the necessary Kube-specific values.

Edit this file from your host system (Linux/Windows):

```bash
/mnt/c/Projects/Mobius/terraform/kube/terraform.tfvars
```

Ensure all required values are set (e.g., Kube config path, namespaces, image versions, credentials, etc).

---

### 3. Pull and Run the Docker Image

Pull the prebuilt Docker image with all required tools:

```bash
docker login wal-artifactory.rocketsoftware.com:6564 -u <username> -p <password>
docker pull wal-artifactory.rocketsoftware.com:6564/terraform-image
docker tag wal-artifactory.rocketsoftware.com:6564/terraform-image terraform-image 
```

> Make sure to replace `<username>` and `<password>` with your actual credentials.

Run the Docker container and mount your local cloned repository:

```bash
docker run -it -v C:/Projects/Mobius/terraform/:/workspace -v C:/Users/skumar6/.kube:/root/.kube terraform-image
(or)
docker run -it -v /mnt/c/Projects/Mobius/terraform/:/workspace -v /home/skumar6/.kube:/root/.kube terraform-image
```

> This mounts the cloned Git repo into the container at `/workspace` and .kube folder to /root.

---

### 4. Run Terraform Inside the Container

Once inside the container shell:

```bash
cd /workspace/kube
terraform init
terraform apply -auto-approve
```

> This will create the complete Mobius Stack in your Kubernetes cluster.

---

## 🧹 Clean Up (Optional but Destructive)

⚠️ **Use with caution.** This will remove the entire stack and all associated resources like databases, PVCs, services, etc.

Only run this if you **no longer need the stack**:

```bash
terraform destroy -auto-approve
```

> Alternatively, you can manually scale down the deployments to `0` if you plan to reuse the environment later. At that point you can rerun `terraform apply -auto-approve` to bring the stack to its desired state.
