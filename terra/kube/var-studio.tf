# Studio specific variables

variable "var_deploy_studio" {
  description = "Deploy Studio"
  type        = bool
  default     = true
}

variable "var_studio_docker_artifactory_url" {
  description = "Studio docker artifactory URL"
  type        = string
  default     = "localhost:5000/studio"
}

variable "var_studio_image" {
  description = "Studio image tag"
  type        = string
  default     = "12.6.1"
}

variable "var_studio_chart_file" {
  description = "Studio helm chart file"
  type        = string
  default     = "studio.tgz"
}

variable "var_studio_replica" {
  description = "Studio replica count"
  type        = number
  default     = 1
}

variable "var_database_studio_schema" {
  description = "Database studio schema"
  type        = string
  default     = "tf_mobius_st"
}

variable "var_studio_service_name" {
  description = "Name to be used for the studio service name"
  type        = string
  default     = "studio"
}

variable "var_studio_pvc_name" {
  description = "Studio PVC name"
  type        = string
  default     = "studio-log-pv-claim"
}

variable "var_studio_pvc_enabled" {
  description = "Enable PVC used for Studio templates and logs"
  type        = bool
  default     = false
}

variable "var_studio_service_account" {
  description = "Studio service account name"
  type        = string
  default     = "studio-sa"
}

variable "var_studio_template_display_name" {
  description = "Optional Studio display template name"
  type        = string
  default     = "Default Template"
}

variable "var_studio_template_local_path" {
  description = "Mandatory local path for Studio project template file"
  type        = string
  default     = "/home/asg/templates/default.proj"
}
