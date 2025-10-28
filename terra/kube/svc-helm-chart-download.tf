# Download Helm Charts from Artifactory
resource "null_resource" "helm_charts_download" {
  depends_on = [
    null_resource.download_eventanalytics_helm_chart,
    null_resource.download_mobius_server_helm_chart,
    null_resource.download_mobius_view_helm_chart,
    null_resource.download_smart_chat_helm_chart,
    null_resource.download_smart_chat_indexing_proxy_helm_chart
  ]

  triggers = { always_run = timestamp() }
}

resource "null_resource" "download_eventanalytics_helm_chart" {

  count = var.var_deploy_eventanalytics ? 1 : 0
  provisioner "local-exec" {
    command = <<EOT
set -e
if [ ! -f "${path.root}/../charts/${var.var_eventanalytics_chart_file}" ]; then
  echo "Downloading Event Analytics Helm chart..."
  curl -X GET "https://wal-artifactory.rocketsoftware.com/artifactory/mobf-helm-dev-wal/${var.var_eventanalytics_chart_file}" \
       -u "${var.var_docker_username}:${var.var_docker_password}:${path.root}/../charts/${var.var_eventanalytics_chart_file}"
else
  echo "Event Analytics chart already exists. Skipping download."
fi
EOT
  }

  triggers = { always_run = timestamp() }
}

resource "null_resource" "download_mobius_server_helm_chart" {

  count = var.var_deploy_mobiusserver ? 1 : 0
  provisioner "local-exec" {
    command = <<EOT
set -e
if [ ! -f "${path.root}/../charts/${var.var_mobiusserver_chart_file}" ]; then
  echo "Downloading Mobius Server Helm chart..."
  curl -X GET "https://wal-artifactory.rocketsoftware.com/artifactory/mobf-helm-dev-wal/${var.var_mobiusserver_chart_file}" \
       -u "${var.var_docker_username}:${var.var_docker_password}:${path.root}/../charts/${var.var_mobiusserver_chart_file}"
else
  echo "Mobius Server chart already exists. Skipping download."
fi
EOT
  }

  triggers = { always_run = timestamp() }
}

resource "null_resource" "download_smart_chat_helm_chart" {

  count = var.var_deploy_smart_chat ? 1 : 0
  provisioner "local-exec" {
    command = <<EOT
set -e
if [ ! -f "${path.root}/../charts/${var.var_smart_chat_chart_file}" ]; then
  echo "Downloading Smart Chat Helm chart..."
  curl -X GET "https://wal-artifactory.rocketsoftware.com/artifactory/bicy-helm-release-wal/smart-chat/${var.var_smart_chat_chart_file}" \
       -u "${var.var_docker_username}:${var.var_docker_password}:${path.root}/../charts/${var.var_smart_chat_chart_file}"
else
  echo "Smart Chat chart already exists. Skipping download."
fi
EOT
  }

  triggers = { always_run = timestamp() }
}

resource "null_resource" "download_smart_chat_indexing_proxy_helm_chart" {

  count = var.var_deploy_smart_chat ? 1 : 0
  provisioner "local-exec" {
    command = <<EOT
set -e
if [ ! -f "${path.root}/../charts/${var.var_smart_chat_indexing_proxy_chart_file}" ]; then
  echo "Downloading Smart Chat Indexing Proxy Helm chart..."
  curl -X GET "https://wal-artifactory.rocketsoftware.com/artifactory/bicy-helm-release-wal/smart-chat-indexing-proxy/${var.var_smart_chat_indexing_proxy_chart_file}" \
       -u "${var.var_docker_username}:${var.var_docker_password}" \
       -o "${path.root}/../charts/${var.var_smart_chat_indexing_proxy_chart_file}"
else
  echo "Smart Chat Indexing Proxy chart already exists. Skipping download."
fi
EOT
  }

  triggers = { always_run = timestamp() }
}

resource "null_resource" "download_mobius_view_helm_chart" {

  count = var.var_deploy_mobiusview ? 1 : 0
  provisioner "local-exec" {
    command = <<EOT
set -e
if [ ! -f "${path.root}/../charts/${var.var_mobiusview_chart_file}" ]; then
  echo "Downloading Mobius View Helm chart..."
  curl -X GET "https://wal-artifactory.rocketsoftware.com/artifactory/mobf-helm-dev-wal/${var.var_mobiusview_chart_file}" \
       -u "${var.var_docker_username}:${var.var_docker_password}" \
       -o "${path.root}/../charts/${var.var_mobiusview_chart_file}"
else
  echo "Mobius View chart already exists. Skipping download."
fi
EOT
  }

  triggers = { always_run = timestamp() }
}