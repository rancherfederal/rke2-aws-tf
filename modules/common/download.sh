#!/bin/bash
set -e

export INSTALL_RKE2_TYPE="${type}"

if [ "$${DEBUG}" == 1 ]; then
  set -x
fi

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

download_rke2() {
  # TODO: Install from repo
  yum install -y http://mirror.centos.org/centos/7/extras/x86_64/Packages/container-selinux-2.119.2-1.911c772.el7_8.noarch.rpm

  curl -fsSL https://raw.githubusercontent.com/rancher/rke2/master/install.sh | sh -s -
}

download_dependencies() {
  yum install -y unzip

  # Install awscli (used for secrets fetching)
  curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
  unzip -q awscliv2.zip
  ./aws/install --bin-dir /usr/bin

  aws configure set default.region $(curl -s http://169.254.169.254/latest/meta-data/placement/region)
}

{
  download_dependencies
  download_rke2
}
