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

config() {
  mkdir -p "/etc/rancher/rke2"
  cat <<-EOF > "/etc/rancher/rke2/config.yaml"
server: "${server}"
token: "${token}"

${config}
EOF
}

start() {
  config

  systemctl enable "rke2-agent"
  systemctl daemon-reload
  systemctl start "rke2-agent"
}

{
  start
}