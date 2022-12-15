#!/bin/bash
set -e

S3KUBECONFIGPATH=$@

# info logs the given argument at info log level.
info() {
    echo "[INFO] " "$@"
}

# warn logs the given argument at warn log level.
warn() {
    echo "[WARN] " "$@" >&2
}

# fatal logs the given argument at fatal log level.
fatal() {
    echo "[ERROR] " "$@" >&2
    exit 1
}

install_awscli() {
  # Install awscli (used for secrets fetching)
  # TODO: Needs to accommodate for Mac and Windows machines
  # NOTE: Assumes unzip has already been installed
  curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
  unzip -q awscliv2.zip
  ./aws/install
  rm -r /aws/
  info 'awscli installed'
}

fetch_kubeconfig(){
    aws s3 cp $@ rke2.yaml
}

install_helm() {
    curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
    chmod 700 get_helm.sh
    ./get_helm.sh
    info 'Helm3 is now installed'
    rm get_helm.sh
}

check_binary(){
    if ! command -v $@ &> /dev/null
    then
        info "'$@' binary is not installed, installing now."
        if [[ $@ == aws ]]
        then 
            install_awscli
        elif [[ $@ == helm ]]
        then 
            install_helm
        fi
    fi
}

add_harbor_repo(){
    helm repo add harbor https://helm.goharbor.io
    info 'Harbor helm repo available.'
}

install_harbor(){
    info 'Installing harbor on RKE2 cluster.'
    helm install harbor harbor/harbor --kubeconfig rke2.yaml
    info 'Harbor is now installed.'
    rm rke2.yaml
}

harbor_install() {
  check_binary aws
  check_binary helm
  add_harbor_repo
  fetch_kubeconfig $S3KUBECONFIGPATH
  install_harbor
}

{
    harbor_install
}
