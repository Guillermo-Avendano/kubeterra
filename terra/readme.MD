# Mobius Stack Deployment using Terraform

This repository contains Terraform configurations to deploy the **Mobius stack**, including **Smart Chat**, across multiple environments:

- Kubernetes (Generic)
- OpenShift
- AWS
- Azure

Each environment has a dedicated folder with specific configuration and usage instructions.  
**Please refer to the individual folders** for detailed steps tailored to each platform.

---

## 🧰 Prerequisites To Run Terraform Locally

Ensure the following tools are installed on your system if you're running Terraform locally:

- `terraform`
- `git`
- `curl`
- `tar` 
- `zip` 
- `unzip`
- `gzip`
- `kubectl` – for Kubernetes
- `oc` – for OpenShift
- `aws` – for AWS deployments

---

## Alternate Using Docker (Recommended)

You can use a prebuilt Docker image that includes all necessary tools preinstalled.

```bash
docker login wal-artifactory.rocketsoftware.com:6564 -u <username> -p <password>
docker pull wal-artifactory.rocketsoftware.com:6564/terraform-image
docker tag wal-artifactory.rocketsoftware.com:6564/terraform-image terraform-image 
docker run -it terraform-image -- bash