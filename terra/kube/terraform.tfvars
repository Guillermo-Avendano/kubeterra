#### Rancher Desktop configurations
### NOTE: When using Rancher its better to pull the required images manually if you are seeing timeout when image cannot be pulled within 5 mins
#var_kubeconfig_path    = "~/.kube/rancher-config"
#var_kubeconfig_context = "rancher-desktop"
#var_namespace_mobius   = "mobius"
#var_pvc_enabled        = false # We cannot use pvc with Rancher Desktop since RD only bounds the pvc when pod is created which wont work in Terraform
##################################################

##### Localkube configurations
var_use_localkube     = true
var_kubeconfig_path   = "~/.kube/config" # Update this as per the config path
#var_kubeconfig_context = ""             # Use the context when there are multiple contexts in the config file otherwise comment it out
var_namespace_mobius  = "mobius"
var_pvc_storage_class = "nfs-storage"
var_pvc_enabled       = true
##################################################

##### Artifactory specific credentials
var_docker_username = ""
var_docker_password = ""
var_docker_email    = ""
##################################################

### This will connect to the Shared Postgres Sql deployed in shared-services namespace of local kube
### Do not modify the below values
### Use pgadmin using the link http://mobkubedev06rx.asgint.loc:31111/pgadmin/
### Login: mobius@pgadmin.com / mobius_123
### Create required schemas manually since terraform cannot create schemas on postgres running inside kube from your machine
var_deploy_postgresql               = true
var_database_provider               = "POSTGRESQL"
var_database_hostname               = "postgresql"
var_database_port                   = "5432"
var_database_user                   = "postgres"
var_database_password               = "mobius_123"
var_database_driver_class_name      = "org.postgresql.Driver"
var_database_platform               = "org.hibernate.dialect.PostgreSQL9Dialect"
var_database_sslmode                = "disable"

### To be disabled when we want to connect to external database
### This will deploy postgres within namespace and create schemas and apps will connect to these databases
### Just uncomment the below block and the values should not be modified
## NOT RECOMMENDED TO DEPLOY POSTGRES WITHIN NAMESPACE UNLESS ABSOLUTELY NECESSARY
#var_deploy_postgresql          = true
#var_database_provider          = "POSTGRESQL"
#var_database_hostname          = "postgresql"
#var_database_port              = "5432"
#var_database_user              = "postgres"
#var_database_password          = "postgres"
#var_database_driver_class_name = "org.postgresql.Driver"
#var_database_platform          = "org.hibernate.dialect.PostgreSQL9Dialect"
#var_database_sslmode           = "disable"

#### Database configurations for External Postgres
#var_database_provider               = "POSTGRESQL"
#var_database_hostname               = "<To_be_updated>"
#var_database_port                   = "<To_be_updated>"
#var_database_user                   = "<To_be_updated>"
#var_database_password               = "<To_be_updated>"
#var_create_database_schema_required = true              # Only Postgres support auto creation of schema
#var_database_driver_class_name      = "org.postgresql.Driver"
#var_database_platform               = "org.hibernate.dialect.PostgreSQL9Dialect"
#var_database_sslmode                = "disable"         # Supports "disable", "allow", "prefer", "require", "verify-ca", "verify-full" - Provide correct certificate in certs\database-root-certificate.crt

#### Database configurations for Sql Server
#var_database_provider               = "SQLSERVER"
#var_database_hostname               = "<To_be_updated>"
#var_database_port                   = "<To_be_updated>"
#var_database_user                   = "<To_be_updated>"
#var_database_password               = "<To_be_updated>"
#var_database_driver_class_name      = "com.microsoft.sqlserver.jdbc.SQLServerDriver"
#var_database_platform               = "org.hibernate.dialect.SQLServer2008Dialect"
#var_database_sslmode                = "disable"          # For Sql server use "encrypt=true" for SSL

#### Database configurations for Oracle
#var_database_provider              = "ORACLE"
#var_database_hostname              = "<To_be_updated>"
#var_database_port                  = "<To_be_updated>"
#var_oracle_mobiusserver_user       = "<To_be_updated>"
#var_oracle_mobiusserver_password   = "<To_be_updated>"
#var_oracle_mobiusview_user         = "<To_be_updated>"
#var_oracle_mobiusview_password     = "<To_be_updated>"
#var_oracle_eventanalytics_user     = "<To_be_updated>"
#var_oracle_eventanalytics_password = "<To_be_updated>"
#var_database_oracle_use_sid         = true               # Application to use SID to connect to Oracle if not it will use Service Name
#var_database_oracle_sid            = "<To_be_updated>"
#var_database_oracle_service_name   = "ORA_NO_SSL"        # This must be set to ORA_NO_SSL or ORA_SSL when var_database_oracle_use_sid is true
#var_database_driver_class_name     = "oracle.jdbc.driver.OracleDriver"
#var_database_platform              = "org.hibernate.dialect.Oracle12cDialect"
#var_database_sslmode               = "disable"          # For Oracle use "enable" for SSL and overwrite the cwallet.sso in the certs folder

#### Database schema name - Make sure to update below to make this unique for each person to avoid conflicts
# Only Postgres supports auto schema creation. For all other database create the schemas before hand
# Below schemas are used only for Postgres and Sql Server. For Oracle use var_oracle_<>_user and var_oracle_<>_password.
var_database_mobiusserver_schema   = "tf_mobius_ms"
var_database_mobiusview_schema     = "tf_mobius_mv"
var_database_eventanalytics_schema = "tf_mobius_ea"
##################################################

### Image URL - Uncomment below if using local image without prefix otherwise comment below to pull it from artifactory
var_mobiusserver_docker_artifactory_url              = "localhost:5000/mobius"
var_mobiusview_docker_artifactory_url                = "localhost:5000/mobius-view"
var_eventanalytics_docker_artifactory_url            = "localhost:5000/eventanalytics"
var_smart_chat_docker_artifactory_url                = "localhost:5000/smart-chat"
var_smart_chat_query_logs_docker_artifactory_url     = "localhost:5000/smart-chat-query-logs"
var_smart_chat_indexing_proxy_docker_artifactory_url = "localhost:5000/smart-chat-indexing-proxy"

##################################################

### Image configurations
var_eventanalytics_image            = "2.0.4"
var_mobiusview_image                = "12.5.0"
var_mobiusserver_image              = "12.5.0"
var_smart_chat_image                = "1.2.8"
var_smart_chat_query_logs_image     = "1.2.2"
var_smart_chat_indexing_proxy_image = "1.2.2"
##################################################

### Helm Chart configurations
var_eventanalytics_chart_file            = "eventanalytics.tgz"
var_mobiusview_chart_file                = "mobiusview.tgz"
var_mobiusserver_chart_file              = "mobius.tgz"
var_smart_chat_chart_file                = "smart-chat.tgz"
var_smart_chat_indexing_proxy_chart_file = "smart-chat-indexing-proxy.tgz"
##################################################

### Configuration to enable or disable the deployment of services
# Supported values true or false
var_deploy_eventanalytics = true # To be disabled when we dont need event analytics
var_deploy_opensearch     = true # To be disabled if we want to connect to opensearch running outside
var_deploy_smart_chat     = true # To be disabled to test Mobius Server with FTS which also deploys elasticsearch if enabled
var_deploy_mobiusview     = true # To be disabled only when we want to test only Mobius Server without View
var_deploy_elasticsearch  = false # To be disabled if we want to connect to elastic running outside also N/A when smart chat is enabled
var_deploy_mobiusserver   = true # To be disabled when we want to test Mobius View with different repository
##################################################

### App specific configurations
# Mobius Server
var_mobius_server_replica           = 1
var_mobius_elastic_enabled          = "YES"             #Applicable only when Smart Chat is disabled
var_mobius_elastic_host             = "elasticsearch-master"
var_mobius_elastic_port             = "9200"
var_mobius_fts_index_name           = "rocket_index" #Applicable to opensearch as well if Smart Chat is enabled or elastic index
var_mobius_server_archive_file_path = "/mnt/efs"
# Mobius View
var_mobius_view_replica             = 1
var_mobius_license                  = "01MOBIUS52464A464C4BF55859518381908FAEA4434F46515E53539681955B454D6240534556564351471D454D12405303565672514759454D1640530556560B51470E454D6040537C56560D514715454D1040536556560351470A454D0540531356560951472A454D2A40531556561D5442BBB6BC5940531A5C53A6A2B6BAB6BC5D40531A5C53A6A2B6BAB6BC2840533456561D5B42BBB6BCBBB3A23556561D5B42BBB6BCBBB3A23656563E514720454D2040535B5055F4AA8D"
# Smart Chat
var_opensearch_host                 = "opensearch-cluster-master"
var_opensearch_port                 = "9200"
var_opensearch_user                 = "admin"
var_opensearch_password             = "Rocket@123#!_"
var_smart_chat_openai_api_key       = "<To_be_updated>"