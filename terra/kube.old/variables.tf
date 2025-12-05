# Terraform label
variable "common_labels" {
  description = "Common labels for all resources"
  type        = map(string)
  default     = {
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
}

variable "var_database_hostname" {
  description = "Database hostname or IP"
  type        = string
  default     = "postgresql"
}

variable "var_database_port" {
  description = "Database port"
  type        = string
  default     = "5432"
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
}

variable "var_database_password" {
  description = "Database password"
  type        = string
  default     = "postgres"
  sensitive   = true
}

variable "var_create_database_schema_required" {
  description = "Flag to determine database schema created needed or not"
  type        = bool
  default     = false
}

variable "var_database_mobiusserver_schema" {
  description = "Database mobiusserver schema"
  type        = string
  default     = "tf_kube_ms"
}

variable "var_database_mobiusview_schema" {
  description = "Database mobiusview schema"
  type        = string
  default     = "tf_kube_mv"
}

variable "var_database_eventanalytics_schema" {
  description = "Database eventanalytics schema"
  type        = string
  default     = "tf_kube_ea"
}

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
  description = "Application to use SID to connect to Oracle if not it will use Service Name"
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
  description = "Mobius docker username"
  type        = string
}

variable "var_docker_password" {
  description = "Mobius docker password"
  type        = string
  sensitive   = true
}

variable "var_docker_email" {
  description = "Mobius docker email"
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

# Docker Images version
variable "var_eventanalytics_image" {
  description = "The image name for eventanalytics"
  type        = string
}

variable "var_mobiusview_image" {
  description = "The image name for mobius view"
  type        = string
}

variable "var_mobiusserver_image" {
  description = "The image name for mobius server"
  type        = string
}

variable "var_smart_chat_image" {
  description = "The image name for smart chat"
  type        = string
}

variable "var_smart_chat_indexing_proxy_image" {
  description = "The image name for smart chat indexing proxy"
  type        = string
}

variable "var_smart_chat_query_logs_image" {
  description = "The image name for smart chat query logs"
  type        = string
}

variable "var_mobius_image" {
  description = "The image name for proxy"
  type        = string
}


# Helm Charts version
variable "var_eventanalytics_chart_file" {
  description = "The Helm chart file name for eventanalytics"
  type        = string
}

variable "var_mobiusview_chart_file" {
  description = "The Helm chart file name for mobius view"
  type        = string
}

variable "var_mobiusserver_chart_file" {
  description = "The Helm chart file name for mobius server"
  type        = string
}

variable "var_smart_chat_chart_file" {
  description = "The Helm chart file name for smart chat"
  type        = string
}

variable "var_smart_chat_indexing_proxy_chart_file" {
  description = "The Helm chart file name for smart chat indexing proxy"
  type        = string
}

# App specific variables
variable "var_mobius_license" {
  description = "Mobius License"
  type        = string
  sensitive   = true
}

variable "var_smart_chat_openai_api_key" {
  description = "API Key for OpenAI to use Smart Chat"
  type        = string
  sensitive   = true
}

# Enable or disable deploying of the application
variable "var_deploy_eventanalytics" {
  description = "Skip deploying eventanalytics"
  type        = bool
}

variable "var_deploy_opensearch" {
  description = "Skip deploying opensearch if we want to connect to opensearch running outside"
  type        = bool
}

variable "var_deploy_smart_chat" {
  description = "Skip deploying Smart Chat. In this case Mobius Server will run with elasticsearch and FTS"
  type        = bool
}

variable "var_deploy_elasticsearch" {
  description = "Skip deploying elasticsearch if we want to connect to elastic running outside"
  type        = bool
}

variable "var_deploy_mobiusserver" {
  description = "Skip deploying mobiusserver"
  type        = bool
}

variable "var_deploy_mobiusview" {
  description = "Skip deploying mobiusview"
  type        = bool
}