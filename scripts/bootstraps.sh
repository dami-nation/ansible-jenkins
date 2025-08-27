#!/bin/bash
set -euxo pipefail
export DEBIAN_FRONTEND=noninteractive

retry() { n=0; until [ "$n" -ge "${2:-5}" ]; do "$@" && break; n=$((n+1)); sleep 5; done; }

# Base deps
retry sudo apt-get update -y
sudo apt-get install -y \
  ca-certificates curl gnupg lsb-release software-properties-common \
  git unzip python3 python3-venv python3-pip \
  openjdk-17-jre maven awscli

# Ansible
retry sudo apt-get install -y ansible

# Jenkins
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | \
  sudo tee /usr/share/keyrings/jenkins-keyring.asc >/dev/null
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" | \
  sudo tee /etc/apt/sources.list.d/jenkins.list >/dev/null
retry sudo apt-get update -y
sudo apt-get install -y jenkins
sudo systemctl enable --now jenkins

# Terraform
curl -fsSL https://apt.releases.hashicorp.com/gpg | \
  gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg >/dev/null
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
  sudo tee /etc/apt/sources.list.d/hashicorp.list >/dev/null
retry sudo apt-get update -y
sudo apt-get install -y terraform

# Docker Engine
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
  gpg --dearmor | sudo tee /etc/apt/keyrings/docker.gpg >/dev/null
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
retry sudo apt-get update -y
sudo apt-get install -y docker-ce docker-ce-cli containerd.io
sudo usermod -aG docker ubuntu || true
sudo usermod -aG docker jenkins || true
sudo systemctl enable --now docker

# kubectl
curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | \
  gpg --dearmor | sudo tee /usr/share/keyrings/kubernetes-archive-keyring.gpg >/dev/null
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | \
  sudo tee /etc/apt/sources.list.d/kubernetes.list >/dev/null
retry sudo apt-get update -y
sudo apt-get install -y kubectl

# Helm (v3.2.4 to match your previous script)
cd /tmp
curl -fsSL -o helm.tar.gz https://get.helm.sh/helm-v3.2.4-linux-amd64.tar.gz
tar -zxf helm.tar.gz
sudo mv linux-amd64/helm /usr/local/bin/helm

# Ensure SSH running
sudo systemctl enable --now ssh || true

echo "bootstrap complete" | sudo tee /var/log/bootstrap.done
