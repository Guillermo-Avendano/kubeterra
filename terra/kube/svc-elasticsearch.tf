# Deploy Elastic Search for Full Text Search if Smart Chat is disabled
resource "helm_release" "elasticsearch" {

  count      = var.var_deploy_elasticsearch == true && var.var_deploy_smart_chat == false ? 1 : 0

  name       = "elasticsearch"
  repository = "https://helm.elastic.co"
  chart      = "elasticsearch"
  version    = "8.5.1"
  namespace = var.var_namespace_mobius
  timeout = 600  # Extend timeout to 10 minutes since elastic will take more than 5 mins (default timeout)

  values = [
    <<EOF
replicas: 1

image: "docker.elastic.co/elasticsearch/elasticsearch"
imageTag: "8.5.1"
imagePullPolicy: "Always"

antiAffinity: "soft"

createCert: false

protocol: http
httpPort: 9200
transportPort: 9300

esJavaOpts: "-Xmx128m -Xms128m"

clusterHealthCheckParams: "wait_for_status=yellow&timeout=60s"

resources:
  requests:
    cpu: "50m"
    memory: "256M"
  limits:
    cpu: "100m"
    memory: "512M"

persistence:
  enabled: false

extraEnvs:
 - name: xpack.security.enabled
   value: "false"
 #- name: discovery.type
 #  value: single-node
 #- name: cluster.initial_master_nodes
 #  value: ""

service:
  type: ClusterIP
EOF
  ]
}
