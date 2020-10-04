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

config() {
  mkdir -p "/etc/rancher/rke2"
  cat <<-EOF > "/etc/rancher/rke2/config.yaml"
server: "https://${server_dns}:9345"

${config}
EOF
}

start() {
  config
  fetch_token

  systemctl enable rke2-agent
  systemctl daemon-reload
  systemctl start rke2-agent
}

{
  start
}