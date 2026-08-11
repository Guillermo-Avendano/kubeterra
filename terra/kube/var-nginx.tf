# Nginx external ingress variables

variable "var_deploy_nginx" {
  description = "Deploy external nginx ingress controller and routes"
  type        = bool
  default     = true
}

variable "var_nginx_namespace" {
  description = "Namespace where nginx ingress controller is deployed"
  type        = string
  default     = "ingress-nginx"
}

variable "var_nginx_version" {
  description = "Nginx ingress controller image tag"
  type        = string
  default     = "v1.4.0"
}

variable "var_nginx_chart_version" {
  description = "Nginx ingress chart version"
  type        = string
  default     = "4.12.3"
}

variable "var_ingress_hostname" {
  description = "Host name used by ingress resources"
  type        = string
  default     = "localhost"
}
