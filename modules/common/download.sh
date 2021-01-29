#!/bin/bash
set -e

preflight_container_selinux_check () {
    if [[ $1 == $2 ]]
    then
        return 0
    fi
    local IFS=.
    local i ver1=($1) ver2=($2)
    for ((i=${#ver1[@]}; i<${#ver2[@]}; i++))
    do
        ver1[i]=0
    done
    for ((i=0; i<${#ver1[@]}; i++))
    do
        if [[ -z ${ver2[i]} ]]
        then
            ver2[i]=0
        fi
        if ((10#${ver1[i]} < 10#${ver2[i]}))
        then
            return 1
        fi
    done
    return 0
}

export INSTALL_RKE2_TYPE="${type}"
export INSTALL_RKE2_VERSION="${rke2_version}"
export SELINUX_DEPENDENCY_VERSION="2.107"

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

read_os() {
  ID=$(grep -oP '(?<=^ID=).+' /etc/os-release | tr -d '"')
  VERSION=$(grep -oP '(?<=^VERSION_ID=).+' /etc/os-release | tr -d '"')
}

get_installer() {
  curl -fsSL https://get.rke2.io -o install.sh
  chmod u+x install.sh
}

install_awscli() {
  # Install awscli (used for secrets fetching)
  # NOTE: Assumes unzip has already been installed
  curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
  unzip -q awscliv2.zip
  ./aws/install --bin-dir /usr/bin

  aws configure set default.region $(curl -s http://169.254.169.254/latest/meta-data/placement/region)
}

do_download() {
  read_os
  get_installer

  case $ID in
  centos)
    yum install -y unzip
    install_awscli

    # TODO: Determine minimum supported version, for now just carry on assuming ignorance
    case $VERSION in
    7*)
      info "Identified CentOS 7"
      INSTALL_RKE2_METHOD='yum' INSTALL_RKE2_TYPE="${type}" ./install.sh

      ;;
    8*)
      info "Identified CentOS 8"
      INSTALL_RKE2_METHOD='yum' INSTALL_RKE2_TYPE="${type}" ./install.sh

      ;;
    esac
    ;;

  rhel)
    yum install -y unzip
    install_awscli

    case $VERSION in
    7*)
      info "Identified RHEL 7"

      # Check if proper version of container-selinux is already installed
      if rpm -q container-selinux 2>&1 > /dev/null && ! preflight_container_selinux_check $(rpm -q container-selinux --qf "%{VERSION}") "$SELINUX_DEPENDENCY_VERSION"; then
          yum install -y http://mirror.centos.org/centos/7/extras/x86_64/Packages/container-selinux-2.119.2-1.911c772.el7_8.noarch.rpm
      fi

      INSTALL_RKE2_METHOD='yum' INSTALL_RKE2_TYPE="${type}" ./install.sh
      ;;
    8*)
      info "Identified RHEL 8"

      INSTALL_RKE2_METHOD='yum' INSTALL_RKE2_TYPE="${type}" ./install.sh
      ;;
    esac

    ;;

  ubuntu)
    info "Identified Ubuntu"
    # TODO: Determine minimum supported version, for now just carry on assuming ignorance
    apt update -y
    apt install -y unzip less iptables resolvconf linux-headers-$(uname -r) telnet
    hostnamectl set-hostname $(curl http://169.254.169.254/latest/meta-data/hostname)

    INSTALL_RKE2_METHOD='tar' INSTALL_RKE2_TYPE="${type}" ./install.sh

    install_awscli
    ;;
  amzn)
    # awscli already present, only need rke2
    yum update -y

    case $VERSION in
    2)
      info "Identified Amazon Linux 2"
      INSTALL_RKE2_METHOD='tar' INSTALL_RKE2_TYPE="${type}" ./install.sh
      ;;
    *)
      info "Identified Amazon Linux 1"
      INSTALL_RKE2_METHOD='tar' INSTALL_RKE2_TYPE="${type}" ./install.sh
      ;;
    esac
    ;;
  *)
    fatal "$${ID} $${VERSION} is not currently supported"
    ;;
  esac
}

{
  do_download
}
