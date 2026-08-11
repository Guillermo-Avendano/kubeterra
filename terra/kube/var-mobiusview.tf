# Mobius View specific variables

variable "var_deploy_mobiusview" {
  description = "Deploy Mobius View"
  type        = bool
  default     = true
}

variable "var_mobiusview_docker_artifactory_url" {
  description = "Mobius View docker artifactory URL"
  type        = string
  default     = "localhost:5000/mobius-view"
}

variable "var_mobiusview_image" {
  description = "Mobius View image tag"
  type        = string
  default     = "12.5.2"
}

variable "var_mobiusview_chart_file" {
  description = "Mobius View helm chart file"
  type        = string
  default     = "mobiusview.tgz"
}

variable "var_mobius_view_replica" {
  description = "Mobius View replica count"
  type        = number
  default     = 1

  validation {
    condition     = var.var_mobius_view_replica > 0 && var.var_mobius_view_replica <= 10
    error_message = "Mobius View replicas must be between 1 and 10."
  }
}

variable "var_database_mobiusview_schema" {
  description = "Database mobiusview schema"
  type        = string
  default     = "tf_mobius_mv"
}

variable "var_mobius_view_pvc_name" {
  description = "Mobius View PVC name"
  type        = string
  default     = "mobius-pv-claim"
}

variable "var_mobius_view_diag_pvc_name" {
  description = "Mobius View Diagnostics PVC name"
  type        = string
  default     = "mobiusview-diagnostic-pv-claim"
}

variable "var_mobius_view_presentation_pvc_name" {
  description = "Mobius View Presentation PVC name"
  type        = string
  default     = "mobiusview-presentation-claim"
}

variable "var_mobius_license" {
  description = "Mobius license"
  type        = string
  default     = "01MOBIUS52464A464C4BF55859518381908FAEA4434F46515E53539681955B454D6240534556564351471D454D12405303565672514759454D1640530556560B51470E454D6040537C56560D514715454D1040536556560351470A454D0540531356560951472A454D2A40531556561D5442BBB6BC5940531A5C53A6A2B6BAB6BC5D40531A5C53A6A2B6BAB6BC2840533456561D5B42BBB6BCBBB3A23556561D5B42BBB6BCBBB3A23656563E514720454D2040535B5055F4AA8D"
  sensitive   = true
}
