#!/bin/bash
export PATH=$PATH:/usr/local/bin
#Install awscli (from https://linoxide.com/how-to-install-aws-cli-on-ubuntu-20-04/)
pip3 install awscli --upgrade --user
if [ $1 = "minikube" ]; then
  #Install minikube (from https://minikube.sigs.k8s.io/docs/start/)
  curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 -o minikube
  sudo install minikube /usr/local/bin/minikube
  minikube config set driver docker
elif [ $1 = "k3d" ]; then
  #Install k3d (from https://k3d.io/)
  curl -s https://raw.githubusercontent.com/rancher/k3d/main/install.sh | TAG=v5.2.2 bash
elif [ $1 = "rosa" ]; then
  curl https://mirror.openshift.com/pub/openshift-v4/clients/rosa/latest/rosa-linux.tar.gz | sudo tar -xz --directory /usr/local/bin/  
elif [ $1 = "eks" ]; then
  #Install boto3
  curl -o get-pip.py https://bootstrap.pypa.io/get-pip.py
  python3 get-pip.py
  sudo ln -s "$HOME/.local/bin/pip" /usr/local/bin/pip
  sudo ln -s "$HOME/.local/bin/pip3" /usr/local/bin/pip3
  pip3 install boto3
  pip3 install --upgrade awscli
  #Install tfenv (from https://github.com/tfutils/tfenv)
  sudo yum install zip unzip jq git -y
  git clone https://github.com/tfutils/tfenv.git $HOME/.tfenv
  sudo ln -s "$HOME/.tfenv/bin/tfenv" /usr/local/bin/tfenv
  tfenv install
  sudo ln -s "$HOME/.tfenv/bin/terraform" /usr/local/bin/terraform
  #Install terragrunt (from https://terragrunt.gruntwork.io/docs/getting-started/install/)
  wget https://github.com/gruntwork-io/terragrunt/releases/download/v0.29.2/terragrunt_linux_amd64
  sudo mv terragrunt_linux_amd64 /usr/local/bin/terragrunt
  chmod +x /usr/local/bin/terragrunt
  #Install hclq (from https://github.com/mattolenik/hclq)
  wget https://github.com/mattolenik/hclq/releases/download/0.5.3/hclq-linux-amd64
  sudo mv hclq-linux-amd64 /usr/local/bin/hclq
  chmod +x /usr/local/bin/hclq
  #Install aws-iam-authenticator (https://docs.aws.amazon.com/eks/latest/userguide/install-aws-iam-authenticator.html)
  curl -o aws-iam-authenticator https://amazon-eks.s3.us-west-2.amazonaws.com/1.21.2/2021-07-05/bin/linux/amd64/aws-iam-authenticator
  sudo mv aws-iam-authenticator /usr/local/bin/aws-iam-authenticator
  chmod +x /usr/local/bin/aws-iam-authenticator
elif [ $1 = "okd" ]; then
  curl -L https://github.com/openshift/okd/releases/download/4.8.0-0.okd-2021-11-14-052418/openshift-client-linux-4.8.0-0.okd-2021-11-14-052418.tar.gz | sudo tar -xz --directory /usr/local/bin/
  curl -L https://github.com/openshift/okd/releases/download/4.8.0-0.okd-2021-11-14-052418/openshift-install-linux-4.8.0-0.okd-2021-11-14-052418.tar.gz | sudo tar -xz --directory /usr/local/bin/
fi

if [ $1 = "eks" ] || [ $1 = "rosa" ] || [ $1 = "okd" ]; then
  # Install Azure Cli and jq to use aws-login for federated logins.
  curl -L https://aka.ms/InstallAzureCli | bash
  sudo yum install jq -y
fi

curl -o kubectl https://s3.us-west-2.amazonaws.com/amazon-eks/1.21.2/2021-07-05/bin/linux/amd64/kubectl
chmod +x kubectl
sudo mv kubectl /usr/local/bin/kubectl
#Install helm (from https://helm.sh/docs/intro/install/)
export DESIRED_VERSION=v3.8.2
curl -s https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
#Install docker-compose
sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose