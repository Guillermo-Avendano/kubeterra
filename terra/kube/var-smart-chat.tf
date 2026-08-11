# Smart Chat specific variables

variable "var_deploy_smart_chat" {
  description = "Deploy Smart Chat"
  type        = bool
  default     = true
}

variable "var_smart_chat_docker_artifactory_url" {
  description = "Smart Chat docker artifactory URL"
  type        = string
  default     = "localhost:5000/smart-chat"
}

variable "var_smart_chat_image" {
  description = "Smart Chat image tag"
  type        = string
  default     = "1.2.8"
}

variable "var_smart_chat_chart_file" {
  description = "Smart Chat helm chart file"
  type        = string
  default     = "smart-chat.tgz"
}

variable "var_smart_chat_indexing_proxy_docker_artifactory_url" {
  description = "Smart Chat Indexing Proxy docker artifactory URL"
  type        = string
  default     = "localhost:5000/smart-chat-indexing-proxy"
}

variable "var_smart_chat_indexing_proxy_image" {
  description = "Smart Chat Indexing Proxy image tag"
  type        = string
  default     = "1.2.2"
}

variable "var_smart_chat_indexing_proxy_chart_file" {
  description = "Smart Chat Indexing Proxy helm chart file"
  type        = string
  default     = "smart-chat-indexing-proxy.tgz"
}

variable "var_smart_chat_query_logs_docker_artifactory_url" {
  description = "Smart Chat Query Logs docker artifactory URL"
  type        = string
  default     = "localhost:5000/smart-chat-query-logs"
}

variable "var_smart_chat_query_logs_image" {
  description = "Smart Chat Query Logs image tag"
  type        = string
  default     = "1.2.2"
}

variable "var_smart_chat_service_name" {
  description = "Smart Chat service name"
  type        = string
  default     = "smart-chat"
}

variable "var_smart_chat_image_pull_secret" {
  description = "Smart Chat image pull secret"
  type        = string
  default     = "docker-registry-secret"
}

variable "var_smart_chat_openai_api_key" {
  description = "Smart Chat OpenAI API Key"
  type        = string
  default     = ""
  sensitive   = true
}

