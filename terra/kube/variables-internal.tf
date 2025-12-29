# The variables defined here are not expected to be modified but used in multiple places so reference in common
# Also the variable that needs to be dynamically changed based on another variables internally
variable "var_database_sslmode" {
  description = "SSL mode to connect with DB for Mobius Server and View"
  type        = string
  default     = "disable"
}

# Variables internal to Mobius Server
variable "var_mobius_nginx_internal_host" {
  description = "Internal nginx full controller name"
  type        = string
  default     = "nginx-internal-controller-ingress-nginx-controller"
}

variable "var_mobius_nginx_internal_port" {
  description = "Internal nginx port"
  type        = string
  default     = "80"
}

variable "var_mobius_server_service_name" {
  description = "Name to be used for the mobius server service name"
  type        = string
  default     = "mobius-server"
}

variable "var_pvc_enabled" {
  description = "Enable or disable all PVC for MS and MV "
  type        = bool
  default     = true
}

variable "var_mobius_pvc_enabled" {
  description = "Enable PVC used for Mobius Server to store archives and mobius.reg"
  type        = bool
  default     = false
}

variable "var_mobius_fts_pvc_enabled" {
  description = "Enable PVC used for FTS data"
  type        = bool
  default     = false
}

variable "var_mobius_diag_pvc_enabled" {
  description = "Enable PVC used for diagnostic data"
  type        = bool
  default     = false
}

variable "var_mobius_view_service_name" {
  description = "Name to be used for the mobius view service name"
  type        = string
  default     = "mobiusview"
}

variable "var_mobius_view_pvc_enabled" {
  description = "Enable PVC used for Mobius view"
  type        = bool
  default     = false
}

variable "var_mobius_view_presentaion_pvc_enabled" {
  description = "Enable PVC used for presentation data"
  type        = bool
  default     = false
}

variable "var_mobius_view_diag_pvc_enabled" {
  description = "Enable PVC used for diagnostic data"
  type        = bool
  default     = false
}

variable "var_eventanalytics_service_name" {
  description = "Name to be used for the eventanalytics service name"
  type        = string
  default     = "eventanalytics"
}

variable "var_smart_chat_query_logs_service_name" {
  description = "Name to be used for the smart chat query logs service name"
  type        = string
  default     = "smart-chat-query-logs"
}

variable "var_smart_chat_indexing_proxy_service_name" {
  description = "Name to be used for the smart chat indexing proxy service name"
  type        = string
  default     = "smart-chat-indexing-proxy"
}


# Dynamic variables
locals {
  #Set to TRUE for more than 1 server replica else FALSE and use internal nginx host and port for init repository
  var_mobius_server_clustering_enabled = var.var_mobius_server_replica > 1 ? "TRUE" : "FALSE"
  var_mobius_server_init_host          = var.var_mobius_server_replica > 1 ? var.var_mobius_nginx_internal_host : var.var_mobius_server_service_name
  var_mobius_server_init_port          = var.var_mobius_server_replica > 1 ? var.var_mobius_nginx_internal_port : "8080"
  var_mobius_nginx_internal_class_name = "nginx-internal-${var.var_namespace_mobius}"

  #Set to true for more than 1 view replica else false
  var_mobius_view_clustering_enabled = var.var_mobius_view_replica > 1 ? true : false

  #Set FTS enabled to TRUE if Smart Chat is enabled otherwise based on user defined var_mobius_elastic_enabled
  var_mobius_fts_enabled = var.var_deploy_smart_chat == true ? tostring("YES") : tostring(var.var_mobius_elastic_enabled)

  #Set FTS host to Smart Chat indexing proxy else set it to elasticsearch
  var_mobius_fts_host = var.var_deploy_smart_chat == true ? "smart-chat-indexing-proxy" : var.var_mobius_elastic_host

  #Set FTS port to Smart Chat indexing proxy port 80 else set it to elasticsearch port 9200
  var_mobius_fts_port = var.var_deploy_smart_chat == true ? "80" : var.var_mobius_elastic_port

  #Set Database Provider UPPER case for Mobius Server and lower case for Mobius View and Event Analytics
  var_database_provider_upper = upper(var.var_database_provider)
  var_database_provider_lower = lower(var.var_database_provider)

  #Set list of variables based on database SSL Mode
  var_database_ssl_enabled = var.var_database_sslmode == "disable" ? false : true
  var_database_protocol    = var.var_database_sslmode == "disable" ? "TCP" : "TCPS"
  var_database_sslmode_url = var.var_database_sslmode == "disable" ? "" : "?${var.var_database_sslmode}"
}

# Generate JDBC URL based on the database type for Mobius View based on SID or Service Name for Oracle
locals {
  var_mobiusview_database_jdbc_url = (
  upper(var.var_database_provider) == "POSTGRESQL" ?
  "jdbc:postgresql://${var.var_database_hostname}:${var.var_database_port}/${var.var_database_mobiusview_schema}${local.var_database_sslmode_url}" :

  upper(var.var_database_provider) == "SQLSERVER" ?
  "jdbc:sqlserver://${var.var_database_hostname}:${var.var_database_port};databaseName=${var.var_database_mobiusview_schema}${var.var_database_sslmode != "disable" ? ";${var.var_database_sslmode}" : ""}" :

  upper(var.var_database_provider) == "ORACLE" && var.var_database_oracle_use_sid == true ?
  "jdbc:oracle:thin:@${var.var_database_hostname}:${var.var_database_port}:${var.var_database_oracle_sid}" :

  upper(var.var_database_provider) == "ORACLE" && var.var_database_oracle_use_sid == false ?
  "jdbc:oracle:thin:@//${var.var_database_hostname}:${var.var_database_port}/${var.var_database_oracle_service_name}" :

  ""
  )
}

locals {

}

# Generate JDBC URL based on the database type for Event Analytics based on SID or Service Name for Oracle
locals {
  var_eventanalytics_database_jdbc_url = (
  upper(var.var_database_provider) == "POSTGRESQL" ?
  "jdbc:postgresql://${var.var_database_hostname}:${var.var_database_port}/${var.var_database_eventanalytics_schema}${local.var_database_sslmode_url}" :

  upper(var.var_database_provider) == "SQLSERVER" ?
  "jdbc:sqlserver://${var.var_database_hostname}:${var.var_database_port};databaseName=${var.var_database_eventanalytics_schema}${var.var_database_sslmode != "disable" ? ";${var.var_database_sslmode}" : ""}" :

  upper(var.var_database_provider) == "ORACLE" && var.var_database_oracle_use_sid == true ?
  "jdbc:oracle:thin:@${var.var_database_hostname}:${var.var_database_port}:${var.var_database_oracle_sid}" :

  upper(var.var_database_provider) == "ORACLE" && var.var_database_oracle_use_sid == false ?
  "jdbc:oracle:thin:@//${var.var_database_hostname}:${var.var_database_port}/${var.var_database_oracle_service_name}" :

  ""
  )
}

# Use Oracle username and password for each service if ORACLE otherwise use common database user and password for POSTGRESQL and SQLSERVER
locals {
  # Set schema to user for Oracle (Only needed for Mobius Server)
  var_database_mobiusserver_schema = upper(var.var_database_provider) == "ORACLE" ? "${var.var_oracle_mobiusserver_user}" : "${var.var_database_mobiusserver_schema}"

  var_mobiusserver_database_user   = upper(var.var_database_provider) == "ORACLE" ? "${var.var_oracle_mobiusserver_user}" : "${var.var_database_user}"
  var_mobiusview_database_user     = upper(var.var_database_provider) == "ORACLE" ? "${var.var_oracle_mobiusview_user}" : "${var.var_database_user}"
  var_eventanalytics_database_user = upper(var.var_database_provider) == "ORACLE" ? "${var.var_oracle_eventanalytics_user}" : "${var.var_database_user}"

  var_mobiusserver_database_password   = upper(var.var_database_provider) == "ORACLE" ? "${var.var_oracle_mobiusserver_password}" : "${var.var_database_password}"
  var_mobiusview_database_password     = upper(var.var_database_provider) == "ORACLE" ? "${var.var_oracle_mobiusview_password}" : "${var.var_database_password}"
  var_eventanalytics_database_password = upper(var.var_database_provider) == "ORACLE" ? "${var.var_oracle_eventanalytics_password}" : "${var.var_database_password}"
}

# Disable all pvc when root variable is disabled. If root pvc is disabled each persistent volume can be enabled or disabled with its own variable
locals {
  var_mobius_pvc_enabled      = var.var_pvc_enabled ? var.var_pvc_enabled : var.var_mobius_pvc_enabled
  var_mobius_diag_pvc_enabled = var.var_pvc_enabled ? var.var_pvc_enabled : var.var_mobius_diag_pvc_enabled
  var_mobius_fts_pvc_enabled  = var.var_pvc_enabled ? var.var_pvc_enabled : var.var_mobius_fts_pvc_enabled

  var_mobius_view_pvc_enabled             = var.var_pvc_enabled ? var.var_pvc_enabled : var.var_mobius_view_pvc_enabled
  var_mobius_view_diag_pvc_enabled        = var.var_pvc_enabled ? var.var_pvc_enabled : var.var_mobius_view_diag_pvc_enabled
  var_mobius_view_presentaion_pvc_enabled = var.var_pvc_enabled ? var.var_pvc_enabled : var.var_mobius_view_presentaion_pvc_enabled
}

