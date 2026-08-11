# AppManager specific variables

variable "var_deploy_appmanager" {
  description = "Deploy AppManager"
  type        = bool
  default     = true
}

variable "var_appmanager_docker_artifactory_url" {
  description = "AppManager docker artifactory URL"
  type        = string
  default     = "localhost:5000/appmanager"
}

variable "var_appmanager_image" {
  description = "AppManager image tag"
  type        = string
  default     = "12.6.1"
}

variable "var_appmanager_chart_file" {
  description = "AppManager helm chart file"
  type        = string
  default     = "appmanager.tgz"
}

variable "var_appmanager_replica" {
  description = "AppManager replica count"
  type        = number
  default     = 1
}

variable "var_database_appmanager_schema" {
  description = "Database appmanager schema"
  type        = string
  default     = "tf_mobius_am"
}

variable "var_appmanager_service_name" {
  description = "Name to be used for the appmanager service name"
  type        = string
  default     = "appmanager"
}

variable "var_appmanager_pvc_name" {
  description = "AppManager PVC name"
  type        = string
  default     = "appmanager-log-pv-claim"
}

variable "var_appmanager_pvc_enabled" {
  description = "Enable PVC used for AppManager logs"
  type        = bool
  default     = false
}

variable "var_appmanager_service_account" {
  description = "AppManager service account name"
  type        = string
  default     = "appmanager-sa"
}
