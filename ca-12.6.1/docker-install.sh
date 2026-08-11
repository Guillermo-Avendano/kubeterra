#!/bin/bash

is_wsl() {
  case "$(uname -r)" in
  *microsoft* ) true ;; # WSL 2
  *Microsoft* ) true ;; # WSL 1
  * ) false;;
  esac
}

if [ "$ZENITH_KUBERNETES_TYPE" != "crc" ]; then
  if is_wsl; then
    #Update Ubuntu distro
    sudo apt-get -y update
    sudo apt-get -y upgrade
    #Install docker
    sudo apt-get -y install containerd docker.io
    #Call visudo
    printf "\n# Docker daemon specification\n%s ALL=(ALL) NOPASSWD: /usr/bin/dockerd\n" $USER | sudo EDITOR='tee -a' visudo
    #Modify bash settings
    printf "\n# Start Docker daemon automatically when logging in if not running.\nRUNNING=\`ps aux | grep dockerd | grep -v grep\`\nif [ -z \"\$RUNNING\" ]; then\n    sudo dockerd > /dev/null 2>&1 &\n    disown\nfi\n" >> ~/.bashrc
    #Add user to docker group
    sudo usermod -aG docker $USER
    echo -e "\nIn 10 seconds this WSL session will be closed. Then reopen a new WSL session to continue..."
    sleep 10; kill -9 $PPID
  else
    curl -fsSL https://get.docker.com | bash
    #Enable docker service
    sudo systemctl enable docker.service
    sudo systemctl start docker.service
    #Add user to docker group
    sudo usermod -aG docker $USER
    sudo chmod 666 /var/run/docker.sock
  fi
fi
