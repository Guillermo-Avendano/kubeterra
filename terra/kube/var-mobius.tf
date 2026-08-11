# Mobius Server specific variables

variable "var_deploy_mobiusserver" {
  description = "Deploy Mobius Server"
  type        = bool
  default     = true
}

variable "var_mobiusserver_docker_artifactory_url" {
  description = "Mobius Server docker artifactory URL"
  type        = string
  default     = "localhost:5000/mobius-server"
}

variable "var_mobiusserver_image" {
  description = "Mobius Server image tag"
  type        = string
  default     = "12.5.2"
}

variable "var_mobius_image" {
  description = "Mobius image tag (legacy)"
  type        = string
  default     = "12.5.2"
}

variable "var_mobiusserver_chart_file" {
  description = "Mobius Server helm chart file"
  type        = string
  default     = "mobius.tgz"
}

variable "var_mobius_server_replica" {
  description = "Mobius Server replica count"
  type        = number
  default     = 1

  validation {
    condition     = var.var_mobius_server_replica > 0 && var.var_mobius_server_replica <= 10
    error_message = "Mobius Server replicas must be between 1 and 10."
  }
}

variable "var_database_mobiusserver_schema" {
  description = "Database mobiusserver schema"
  type        = string
  default     = "tf_mobius_ms"
}

variable "var_mobius_pvc_name" {
  description = "Mobius PVC name"
  type        = string
  default     = "mobius-pv-claim"
}

variable "var_mobius_fts_pvc_name" {
  description = "Mobius FTS PVC name"
  type        = string
  default     = "mobius-fts-pv-claim"
}

variable "var_mobius_diag_pvc_name" {
  description = "Mobius Diagnostics PVC name"
  type        = string
  default     = "mobius-diagnostic-pv-claim"
}

variable "var_mobius_service_account" {
  description = "Mobius service account name"
  type        = string
  default     = "mobius-sa"
}

variable "var_mobius_elastic_enabled" {
  description = "Enable Mobius Elasticsearch"
  type        = string
  default     = "YES"

  validation {
    condition     = contains(["YES", "NO"], var.var_mobius_elastic_enabled)
    error_message = "Mobius Elasticsearch must be YES or NO."
  }
}

variable "var_mobius_elastic_host" {
  description = "Mobius Elasticsearch host"
  type        = string
  default     = "elasticsearch-master"

  validation {
    condition     = length(var.var_mobius_elastic_host) > 0
    error_message = "Elasticsearch host cannot be empty."
  }
}

variable "var_mobius_elastic_port" {
  description = "Mobius Elasticsearch port"
  type        = string
  default     = "9200"

  validation {
    condition     = can(tonumber(var.var_mobius_elastic_port)) && tonumber(var.var_mobius_elastic_port) > 0 && tonumber(var.var_mobius_elastic_port) <= 65535
    error_message = "Elasticsearch port must be a valid port number between 1 and 65535."
  }
}

variable "var_mobius_fts_index_name" {
  description = "Mobius FTS index name"
  type        = string
  default     = "rocket_index"
}

variable "var_mobius_server_archive_file_path" {
  description = "Mobius Server archive file path"
  type        = string
  default     = "/mnt/efs"
}

variable "var_mobius_image_pull_secret" {
  description = "Mobius image pull secret"
  type        = string
  default     = "docker-registry-secret"
}

