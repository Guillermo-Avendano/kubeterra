#!/bin/bash

# -----------------
# 1. Credential Variables (Docker)
# -----------------

# Check and set TF_VAR_var_docker_username
if [ -z "$TF_VAR_var_docker_username" ]; then
    echo "[INFO] Setting TF_VAR_var_docker_username"
    export TF_VAR_var_docker_username="gavendano@rs.com"
else
    echo "[INFO] TF_VAR_var_docker_username is already set. Skipping."
fi

# Check and set TF_VAR_var_docker_password
if [ -z "$TF_VAR_var_docker_password" ]; then
    echo "[INFO] Setting TF_VAR_var_docker_password"
    export TF_VAR_var_docker_password="yyy#" # **NOTE:** Replace 'yyy#' with the actual password.
else
    echo "[INFO] TF_VAR_var_docker_password is already set. Skipping."
fi

# Derive the email from the username if the email is not set
if [ -z "$TF_VAR_var_docker_email" ]; then
    echo "[INFO] Setting TF_VAR_var_docker_email"
    export TF_VAR_var_docker_email="$TF_VAR_var_docker_username"
else
    echo "[INFO] TF_VAR_var_docker_email is already set. Skipping."
fi

# -----------------
# 2. License / API Key Variables
# -----------------

# Check and set TF_VAR_var_mobius_license
if [ -z "$TF_VAR_var_mobius_license" ]; then
    echo "[INFO] Setting TF_VAR_var_mobius_license"
    export TF_VAR_var_mobius_license="01MOBIUS52464A464C4BF55859518381908FAEA4434F46515E53539681955B454D6240534556564351471D454D12405303565672514759454D1640530556560B51470E454D6040537C56560D514715454D1040536556560351470A454D0540531356560951472A454D2A40531556561D5442BBB6BC5940531A5C53A6A2B6BAB6BC5D40531A5C53A6A2B6BAB6BC2840533456561D5B42BBB6BCBBB3A23556561D5B42BBB6BCBBB3A23656563E514720454D2040535B5055F4AA8D"
else
    echo "[INFO] TF_VAR_var_mobius_license is already set. Skipping."
fi

# Check and set TF_VAR_var_smart_chat_openai_api_key
if [ -z "$TF_VAR_var_smart_chat_openai_api_key" ]; then
    echo "[INFO] Setting TF_VAR_var_smart_chat_openai_api_key"
    export TF_VAR_var_smart_chat_openai_api_key="yyyy" # **NOTE:** Replace 'yyyy' with the actual key.
else
    echo "[INFO] TF_VAR_var_smart_chat_openai_api_key is already set. Skipping."
fi

# -----------------
# 3. General Environment Variables
# -----------------

# DOCKER_USERNAME should reflect TF_VAR_var_docker_username
if [ -z "$DOCKER_USERNAME" ]; then
    echo "[INFO] Setting DOCKER_USERNAME"
    export DOCKER_USERNAME="$TF_VAR_var_docker_username"
else
    echo "[INFO] DOCKER_USERNAME is already set. Skipping."
fi

# Check and set KUBE_SOURCE_REGISTRY
if [ -z "$KUBE_SOURCE_REGISTRY" ]; then
    echo "[INFO] Setting KUBE_SOURCE_REGISTRY"
    export KUBE_SOURCE_REGISTRY=registry.rocketsoftware.com
else
    echo "[INFO] KUBE_SOURCE_REGISTRY is already set. Skipping."
fi

echo "--- All variables checked. ---"