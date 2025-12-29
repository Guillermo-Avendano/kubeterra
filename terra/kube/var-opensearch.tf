# OpenSearch specific variables

variable "var_deploy_opensearch" {
  description = "Deploy OpenSearch"
  type        = bool
  default     = true
}

variable "var_opensearch_host" {
  description = "OpenSearch host"
  type        = string
  default     = "opensearch-cluster-master"

  validation {
    condition     = length(var.var_opensearch_host) > 0
    error_message = "OpenSearch host cannot be empty."
  }
}

variable "var_opensearch_port" {
  description = "OpenSearch port"
  type        = string
  default     = "9200"

  validation {
    condition     = can(tonumber(var.var_opensearch_port)) && tonumber(var.var_opensearch_port) > 0 && tonumber(var.var_opensearch_port) <= 65535
    error_message = "OpenSearch port must be a valid port number between 1 and 65535."
  }
}

variable "var_opensearch_user" {
  description = "OpenSearch username"
  type        = string
  default     = "admin"

  validation {
    condition     = length(var.var_opensearch_user) > 0
    error_message = "OpenSearch username cannot be empty."
  }
}

variable "var_opensearch_password" {
  description = "OpenSearch password"
  type        = string
  default     = "Rocket@123#!_"
  sensitive   = true

  validation {
    condition     = length(var.var_opensearch_password) > 0
    error_message = "OpenSearch password cannot be empty."
  }
}
