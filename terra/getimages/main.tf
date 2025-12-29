# main.tf
# 
# SIMPLIFIED APPROACH: Use native shell script instead of Docker provider
# 
# The Docker provider in Terraform has limitations with authentication and pulling/pushing images.
# This Terraform configuration now uses a simple shell script that handles all operations.

# 1. Global Variables (Locals)
locals {
  source_registry = var.g_source_registry
  target_registry = var.g_target_registry
  source_registry_username = var.g_rocket_user
  source_registry_password = var.g_rocket_password
  images_csv_path = "${path.module}/../conf/images.csv"
}

# ⚠️ IMPORTANT: PREFERRED METHOD
# Instead of using Terraform for Docker image operations, use the provided shell script:
#
# ./migrate-images.sh [source_registry] [target_registry] [username] [password] [csv_file]
#
# Example:
# ./migrate-images.sh registry.rocketsoftware.com localhost:5000 guillermoa@rs.com "Yapeyu222#" ../conf/images.csv
#
# OR with docker login already done:
# ./migrate-images.sh registry.rocketsoftware.com localhost:5000
#
# This script is much more reliable than using the Terraform Docker provider.

# Execute the migration script using Terraform
resource "null_resource" "migrate_images" {
  provisioner "local-exec" {
    command = "cd ${path.module} && chmod +x ./migrate-images.sh && ./migrate-images.sh '${local.source_registry}' '${local.target_registry}' '${local.source_registry_username}' '${local.source_registry_password}' '${local.images_csv_path}'"
  }
}