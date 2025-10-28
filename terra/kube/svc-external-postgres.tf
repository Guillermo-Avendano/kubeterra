# Use Postgres
terraform {
  required_providers {
    postgresql = {
      source  = "cyrilgdn/postgresql"
      version = ">=1.21.0"
    }
  }
}

provider "postgresql" {
  host     = var.var_database_hostname
  port     = var.var_database_port
  database = "postgres"
  username = var.var_database_user
  password = var.var_database_password
  sslmode  = "disable"  # Leave this to disable even when using SSL since it is only used to create schemas
}

# Create database schema for Mobius Server, Mobius View and Event Analytics
resource "postgresql_database" "postgres_schema_mobiusserver" {

  count = var.var_deploy_postgresql == false && var.var_deploy_mobiusserver && var.var_create_database_schema_required && lower(var.var_database_provider) == "postgresql" ? 1 : 0

  name             = var.var_database_mobiusserver_schema
  owner            = "postgres"
  encoding         = "UTF8"
  lc_collate       = "C"
  lc_ctype         = "C"
  template         = "template0"
  connection_limit = -1
}

resource "postgresql_database" "postgres_schema_mobiusview" {

  count = var.var_deploy_postgresql == false && var.var_deploy_mobiusview && var.var_create_database_schema_required && lower(var.var_database_provider) == "postgresql" ? 1 : 0

  name             = var.var_database_mobiusview_schema
  owner            = "postgres"
  encoding         = "UTF8"
  lc_collate       = "C"
  lc_ctype         = "C"
  template         = "template0"
  connection_limit = -1
}

resource "postgresql_database" "postgres_schema_eventanalytics" {

  count = var.var_deploy_postgresql == false && var.var_deploy_eventanalytics && var.var_create_database_schema_required && lower(var.var_database_provider) == "postgresql" ? 1 : 0

  name             = var.var_database_eventanalytics_schema
  owner            = "postgres"
  encoding         = "UTF8"
  lc_collate       = "C"
  lc_ctype         = "C"
  template         = "template0"
  connection_limit = -1
}


