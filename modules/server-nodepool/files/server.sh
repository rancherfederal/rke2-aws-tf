#!/bin/bash
set -e

if [ "$${DEBUG}" == 2 ]; then
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

# If launch_index == 0 and apiserver is not ready, initialize a new leader
#   else, join a new server to an existing cluster

identify() {
  NODE_TYPE="server"

  TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
  LAUNCH_INDEX=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/ami-launch-index)

  if [ $LAUNCH_INDEX -eq 0 ]; then
    info "Identified potential leader from zero launch index"

    if timeout 1 bash -c "true <>/dev/tcp/${server_dns}/6443" 2>/dev/null
    then
      info "API server available, identifying as server joining existing cluster"
    else
      info "API server unavailable, identifying as leader"
      NODE_TYPE="leader"
    fi
  else
    info "Identified as server joining existing cluster from non zero launch index"
  fi
}

cp_wait() {
  while true; do
    if timeout 1 bash -c "true <>/dev/tcp/${server_dns}/6443" 2>/dev/null; then
      info "Cluster is ready"
      break
    fi
    info "Waiting for cluster to be ready..."
    sleep 10
  done
}

base_config() {
  mkdir -p "/etc/rancher/rke2"
  cat <<-EOF > "/etc/rancher/rke2/config.yaml"
token: ${token}
tls-san:
  - ${server_dns}

${config}
EOF
}

server_config() {
  cat <<-EOF >> "/etc/rancher/rke2/config.yaml"
server: "https://${server_dns}:9345"
EOF
}

leader_config() {
  cat <<-EOF >> "/etc/rancher/rke2/config.yaml"
cluster-init: true
EOF
}

start() {
  base_config

  case $NODE_TYPE in
  leader)
    leader_config
    ;;
  *)
    server_config
    cp_wait
    ;;
  esac

  systemctl enable "rke2-server"
  systemctl daemon-reload
  systemctl start "rke2-server"
}

{
  identify
  start
}