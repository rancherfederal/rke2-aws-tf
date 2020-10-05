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

      # TODO: Fix this
      sleep 30
      break
    fi
    info "Waiting for cluster to be ready..."
    sleep 10
  done
}

fetch_token() {
  # Validate aws caller identity, fatal if not valid
  if ! aws sts get-caller-identity 2>/dev/null; then
    fatal "No valid aws caller identity"
  fi

  # Either
  #   a) fetch secret from secrets manager
  #   b) if secrets manager not found, try and fetch from s3 bucket
  #   c) fail
  if token=$(aws secretsmanager get-secret-value --secret-id ${token_address} --query 'SecretString' --output text 2>/dev/null); then
    info "Found token from secretsmanager"
  elif token=$(aws s3 cp ${token_address} - 2>/dev/null);then
    info "Found token from s3 object"
  else
    fatal "Could not find cluster token from secretsmanager or s3"
  fi

  echo "token: $${token}" >> "/etc/rancher/rke2/config.yaml"
}

base_config() {
  mkdir -p "/etc/rancher/rke2"
  cat <<-EOF > "/etc/rancher/rke2/config.yaml"
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
EOF
}

start() {
  base_config
  fetch_token

  case $NODE_TYPE in
  leader)
    leader_config
    ;;
  *)
    server_config
    cp_wait
    ;;
  esac

  systemctl enable rke2-server
  systemctl daemon-reload
  systemctl start rke2-server

  export KUBECONFIG=/etc/rancher/rke2/rke2.yaml
  export PATH=$PATH:/var/lib/rancher/rke2/bin
}

pre_userdata() {
  info "Beginning user defined pre userdata"
  ${pre_userdata}
  info "Ending user defined pre userdata"
}

post_userdata() {
  info "Beginning user defined post userdata"
  ${post_userdata}
  info "Ending user defined post userdata"
}

{
  pre_userdata

  identify
  start

  post_userdata
}