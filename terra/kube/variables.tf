# Core variables shared across modules

# Terraform label
variable "common_labels" {
  description = "Common labels for all resources"
  type        = map(string)
  default = {
    created_by  = "terraform"
    environment = "dev"
    team        = "mobius"
  }
}

# Local kube configs
variable "var_use_localkube" {
  description = "Set to true to use Local Kube Cluster"
  type        = bool
  default     = false
}

variable "var_kubeconfig_path" {
  description = "Kubeconfig file path"
  type        = string
  default     = "~/.kube/config"
}

variable "var_kubeconfig_context" {
  description = "Kubernetes Context"
  type        = string
  default     = ""
}

# Namespaces
variable "var_namespace_mobius" {
  description = "Namespace for mobius services"
  type        = string
  default     = "mobius"

  validation {
    condition     = can(regex("^[a-z0-9]([a-z0-9-]*[a-z0-9])?$", var.var_namespace_mobius))
    error_message = "Namespace must be lowercase alphanumeric with hyphens, must start and end with alphanumeric character."
  }

  validation {
    condition     = length(var.var_namespace_mobius) <= 63
    error_message = "Namespace name must be 63 characters or less."
  }
}

# Database Variables
variable "var_deploy_postgresql" {
  description = "Deploy Postgressql within namespace"
  type        = bool
  default     = false
}

variable "var_database_provider" {
  description = "Database Provider"
  type        = string
  default     = "POSTGRESQL"

  validation {
    condition     = contains(["POSTGRESQL", "SQLSERVER", "ORACLE"], var.var_database_provider)
    error_message = "Database provider must be one of: POSTGRESQL, SQLSERVER, ORACLE."
  }
}

variable "var_database_hostname" {
  description = "Database hostname or IP"
  type        = string
  default     = "postgresql"

  validation {
    condition     = length(var.var_database_hostname) > 0
    error_message = "Database hostname cannot be empty."
  }
}

variable "var_database_port" {
  description = "Database port"
  type        = string
  default     = "5432"

  validation {
    condition     = can(tonumber(var.var_database_port)) && tonumber(var.var_database_port) > 0 && tonumber(var.var_database_port) <= 65535
    error_message = "Database port must be a valid port number between 1 and 65535."
  }
}

variable "var_database_driver_class_name" {
  description = "Database driver name"
  type        = string
  default     = "org.postgresql.Driver"
}

variable "var_database_platform" {
  description = "Database Platform"
  type        = string
  default     = "org.hibernate.dialect.PostgreSQL9Dialect"
}

variable "var_database_user" {
  description = "Database username"
  type        = string
  default     = "postgres"

  validation {
    condition     = length(var.var_database_user) > 0
    error_message = "Database username cannot be empty."
  }
}

variable "var_database_password" {
  description = "Database password"
  type        = string
  default     = "postgres"
  sensitive   = true

  validation {
    condition     = length(var.var_database_password) > 0
    error_message = "Database password cannot be empty."
  }
}

variable "var_create_database_schema_required" {
  description = "Flag to determine database schema creation"
  type        = bool
  default     = false
}

# Oracle overrides
variable "var_oracle_mobiusserver_user" {
  description = "Oracle mobiusserver user or schema"
  type        = string
  default     = "tf_kube_oracle_ms"
}

variable "var_oracle_mobiusserver_password" {
  description = "Oracle mobiusserver user password"
  type        = string
  default     = "oracle"
}

variable "var_oracle_mobiusview_user" {
  description = "Oracle mobiusview user or schema"
  type        = string
  default     = "tf_kube_oracle_mv"
}

variable "var_oracle_mobiusview_password" {
  description = "Oracle mobiusview user password"
  type        = string
  default     = "oracle"
}

variable "var_oracle_eventanalytics_user" {
  description = "Oracle eventanalytics user or schema"
  type        = string
  default     = "tf_kube_oracle_ea"
}

variable "var_oracle_eventanalytics_password" {
  description = "Oracle eventanalytics user password"
  type        = string
  default     = "oracle"
}

variable "var_database_oracle_sid" {
  description = "Oracle SID"
  type        = string
  default     = "ORCL"
}

variable "var_database_oracle_use_sid" {
  description = "Use SID to connect to Oracle; if false, use Service Name"
  type        = bool
  default     = true
}

variable "var_database_oracle_service_name" {
  description = "Oracle Service name"
  type        = string
  default     = "ORA_NO_SSL"
}

# Artifactory variables
variable "var_mobius_docker_registry" {
  description = "Mobius docker registry"
  type        = string
  default     = "localhost:5000"
}

variable "var_smart_chat_docker_registry" {
  description = "Smart Chat docker registry"
  type        = string
  default     = "localhost:5000"
}

variable "var_docker_username" {
  description = "Docker registry username"
  type        = string
}

variable "var_docker_password" {
  description = "Docker registry password"
  type        = string
  sensitive   = true
}

variable "var_docker_email" {
  description = "Docker registry email"
  type        = string
}

# Infra variables
variable "var_pvc_storage_class" {
  description = "PVC Storage Class"
  type        = string
  default     = "nfs-client"
}

variable "var_pvc_storage_capacity" {
  description = "PVC Storage Capacity"
  type        = string
  default     = "1Gi"
}
