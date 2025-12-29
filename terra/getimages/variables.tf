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
variable "g_source_registry" {
  description = "Rocket Registry URL"
  type        = string
  default     = "registry.rocketsoftware.com"
}

variable "g_target_registry" {
  description = "Local Registry URL"
  type        = string
  default     = "localhost:5000"
}


variable "g_rocket_user" {
  description = "Rocket Registry Username"
  type        = string
  default     = "gavendano@rs.com"
}

variable "g_rocket_password" {
  description = "Rocket Registry Password"
  type        = string
  default     = ""
}
