# ProcessEngine specific variables

variable "var_deploy_processengine" {
  description = "Deploy ProcessEngine"
  type        = bool
  default     = true
}

variable "var_processengine_docker_artifactory_url" {
  description = "ProcessEngine docker artifactory URL"
  type        = string
  default     = "localhost:5000/processengine"
}

variable "var_processengine_image" {
  description = "ProcessEngine image tag"
  type        = string
  default     = "12.6.1"
}

variable "var_processengine_chart_file" {
  description = "ProcessEngine helm chart file"
  type        = string
  default     = "processengine.tgz"
}

variable "var_processengine_replica" {
  description = "ProcessEngine replica count"
  type        = number
  default     = 1
}

variable "var_database_processengine_flowable_schema" {
  description = "Database processengine flowable schema"
  type        = string
  default     = "tf_mobius_pe_flowable"
}

variable "var_database_processengine_root_schema" {
  description = "Database processengine root schema"
  type        = string
  default     = "tf_mobius_pe_root"
}

variable "var_processengine_service_name" {
  description = "Name to be used for the processengine service name"
  type        = string
  default     = "processengine"
}

variable "var_processengine_pvc_name" {
  description = "ProcessEngine PVC name"
  type        = string
  default     = "process-pv-claim"
}

variable "var_processengine_pvc_enabled" {
  description = "Enable PVC used for ProcessEngine mounted paths"
  type        = bool
  default     = false
}

variable "var_processengine_service_account" {
  description = "ProcessEngine service account name"
  type        = string
  default     = "processengine-sa"
}

variable "var_processengine_storage_path" {
  description = "ProcessEngine storage path"
  type        = string
  default     = "/home/asg/processengine/directorymonitor"
}

variable "var_processengine_target_path" {
  description = "ProcessEngine target path"
  type        = string
  default     = "/home/asg/processengine/target"
}

variable "var_processengine_mount_name" {
  description = "ProcessEngine mount name"
  type        = string
  default     = "process-data"
}

variable "var_processengine_ldap_enabled" {
  description = "Enable LDAP on ProcessEngine"
  type        = bool
  default     = false
}

variable "var_processengine_agent_task_enabled" {
  description = "Enable agent task on ProcessEngine"
  type        = bool
  default     = false
}

variable "var_jwt_private_key" {
  description = "JWT private key shared by CA components"
  type        = string
  default     = ""
  sensitive   = true
}

variable "var_jwt_public_key" {
  description = "JWT public key shared by CA components"
  type        = string
  default     = ""
}

variable "var_process_mail_host" {
  description = "Mail server host for ProcessEngine"
  type        = string
  default     = ""
}

variable "var_process_mail_from_email" {
  description = "From email for ProcessEngine mail"
  type        = string
  default     = ""
}

variable "var_process_mail_username" {
  description = "Mail username for ProcessEngine"
  type        = string
  default     = ""
}

variable "var_process_mail_password" {
  description = "Mail password for ProcessEngine"
  type        = string
  default     = ""
  sensitive   = true
}

variable "var_processengine_openai_api_key" {
  description = "OpenAI API key for ProcessEngine agent tasks"
  type        = string
  default     = ""
  sensitive   = true
}

variable "var_mcp_server_name" {
  description = "MCP server name for ProcessEngine"
  type        = string
  default     = ""
}

variable "var_mcp_server_url" {
  description = "MCP server URL for ProcessEngine"
  type        = string
  default     = ""
}

variable "var_mcp_server_path" {
  description = "MCP server tools path for ProcessEngine"
  type        = string
  default     = ""
}
