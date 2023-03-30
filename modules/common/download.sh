#!/bin/bash
set -e

export INSTALL_RKE2_TYPE="${type}"
export INSTALL_RKE2_VERSION="${rke2_version}"

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
  info "OS identified as $ID - $VERSION"
}

get_installer() {
  info 'Curl-ing RKE2 install script from "${rke2_install_script_url}"'
  curl -fsSL ${rke2_install_script_url} -o install.sh
  chmod u+x install.sh
  info 'RKE2 install script downloaded'
}

install_awscli() {
  # Install awscli (used for secrets fetching)
  # NOTE: Assumes unzip has already been installed
  info 'Installing AWSCLI from "${awscli_url}"'
  curl -fsSL ${awscli_url} -o awscliv2.zip
  unzip -q awscliv2.zip
  ./aws/install --bin-dir /usr/bin --update
  rm -f awscliv2.zip
  info 'AWSCLI installed'
}

install_unzip_el() {
  if [ -z "${unzip_rpm_url}" ]; then
    info "Installing unzip via YUM"
    yum install -y unzip
  else
    info "Installing unzip via ${unzip_rpm_url}"
    curl -fsSL ${unzip_rpm_url} -o unzip.rpm
    rpm -ivh unzip.rpm; rm -f unzip.rpm
  fi
}

do_download() {
  read_os
  get_installer

  case $ID in
  centos | rocky | rhel)
    info "Installing RKE2 for EL-based distro"
    
    install_unzip_el

    install_awscli

    # TODO: Determine minimum supported version, for now just carry on assuming ignorance
    case $VERSION in
    7*)
      if [ $ID == "rhel" ]; then
        rpm --import http://mirror.centos.org/centos/RPM-GPG-KEY-CentOS-7
        yum install -y http://mirror.centos.org/centos/7/extras/x86_64/Packages/container-selinux-2.119.2-1.911c772.el7_8.noarch.rpm
      fi
      INSTALL_RKE2_METHOD='yum' INSTALL_RKE2_TYPE="${type}" ./install.sh

      ;;
    8*)
      INSTALL_RKE2_METHOD='yum' INSTALL_RKE2_TYPE="${type}" ./install.sh

      ;;
    esac
    ;;

  ubuntu)
    info "Installing RKE2 for Ubuntu"
    # TODO: Determine minimum supported version, for now just carry on assuming ignorance
    apt update -y
    apt install -y unzip less iptables resolvconf linux-headers-$(uname -r) telnet
    hostnamectl set-hostname "$(curl http://169.254.169.254/latest/meta-data/hostname)"

    INSTALL_RKE2_METHOD='tar' INSTALL_RKE2_TYPE="${type}" ./install.sh
    
    install_awscli
    ;;
  amzn)
    info "Installing RKE2 for Amazon Linux"
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
  rm -f install.sh
}

{
  info "Beginning download user-data"
  do_download
  info "Ending download user-data"
}
