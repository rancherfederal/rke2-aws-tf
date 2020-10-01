#!/bin/bash
set -e

build_config() {
  mkdir -p "/etc/rancher/rke2"
  cat <<-EOF > "/etc/rancher/rke2/config.yaml"
token: ${token}
server: ${server}

${config}
EOF
}

{
  build_config
}