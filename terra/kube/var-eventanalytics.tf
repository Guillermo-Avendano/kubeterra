# Event Analytics specific variables

variable "var_deploy_eventanalytics" {
  description = "Deploy Event Analytics"
  type        = bool
  default     = true
}

variable "var_eventanalytics_docker_artifactory_url" {
  description = "Event Analytics docker artifactory URL"
  type        = string
  default     = "localhost:5000/eventanalytics"
}

variable "var_eventanalytics_image" {
  description = "Event Analytics image tag"
  type        = string
  default     = "2.0.9"
}

variable "var_eventanalytics_chart_file" {
  description = "Event Analytics helm chart file"
  type        = string
  default     = "eventanalytics.tgz"
}

variable "var_database_eventanalytics_schema" {
  description = "Database eventanalytics schema"
  type        = string
  default     = "tf_mobius_ea"
}
