# Deploy Postgresql
resource "helm_release" "postgresql" {

  count = var.var_deploy_postgresql ? 1 : 0

  name       = "postgresql"
  namespace  = var.var_namespace_mobius
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "postgresql"
  version    = "11.8.2"

  # Ensure secret is created before deploying PostgreSQL
  depends_on = [
    kubernetes_secret.postgresql_secret
  ]

  values = [
    <<-EOT
image:
  tag: latest

auth:
  existingSecret: postgresql
  secretKeys:
    adminPasswordKey: postgres-password
    userPasswordKey: password
  username: ${var.var_database_user}
  database: postgres

service:
  ports:
    postgresql: 5432

fullnameOverride: postgresql

resources:
  requests:
    cpu: 250m
    memory: 256Mi

primary:
  persistence:
    enabled: false
    storageClass: ""
    size: 1Gi

  extraEnvVars:
    - name: HOME
      value: "/bitnami/postgresql/data"
    - name: PGHOST
      value: "localhost"
    - name: PGSSLMODE
      value: "prefer"

  initdb:
    scripts:
      mobius-init.sql: |
        CREATE ROLE postgres LOGIN PASSWORD '${var.var_database_password}';
        GRANT postgres TO ${var.var_database_user};

        CREATE DATABASE ${var.var_database_mobiusserver_schema} OWNER ${var.var_database_user} ENCODING 'UTF8' TEMPLATE template0 LC_COLLATE 'C' LC_CTYPE 'C' CONNECTION LIMIT -1;
        CREATE DATABASE ${var.var_database_mobiusview_schema} OWNER ${var.var_database_user} ENCODING 'UTF8' TEMPLATE template0 LC_COLLATE 'C' LC_CTYPE 'C' CONNECTION LIMIT -1;
        CREATE DATABASE ${var.var_database_eventanalytics_schema} OWNER ${var.var_database_user} ENCODING 'UTF8' TEMPLATE template0 LC_COLLATE 'C' LC_CTYPE 'C' CONNECTION LIMIT -1;
EOT
  ]
}
