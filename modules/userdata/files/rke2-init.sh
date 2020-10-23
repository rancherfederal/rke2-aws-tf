#!/bin/sh

export TYPE="${type}"
export CCM="${ccm}"

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
  cat <<EOF > "/etc/rancher/rke2/config.yaml"
${config}
EOF
}

append_config() {
  echo $1 >> "/etc/rancher/rke2/config.yaml"
}

# The most simple "leader election" you've ever seen in your life
elect_leader() {
  SERVER_TYPE="server"

  # Fetch other running instances in ASG
  instance_id=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
  asg_name=$(aws autoscaling describe-auto-scaling-instances --instance-ids "$instance_id" --query 'AutoScalingInstances[*].AutoScalingGroupName' --output text)
  instances=$(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-name "$asg_name" --query 'AutoScalingGroups[*].Instances[?HealthStatus==`Healthy`].InstanceId' --output text)

  # Simply identify the leader as the first of the instance ids sorted alphanumerically
  leader=$(echo $instances | tr ' ' '\n' | sort -n | head -n1)
  if [ $instance_id = $leader ]; then
    SERVER_TYPE="leader"
    info "Electing as cluster leader"
  else
    info "Electing as joining server"
  fi
}

identify() {
  TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")

  if timeout 1 bash -c "true <>/dev/tcp/${server_url}/6443" 2>/dev/null
  then
    info "API server available, identifying as server joining existing cluster"
  else
    info "API server unavailable, performing simple leader election"

    elect_leader
  fi
}

cp_wait() {
  while true; do
    if timeout 1 bash -c "true <>/dev/tcp/${server_url}/6443" 2>/dev/null; then
      info "Cluster is ready"

      # Let things settle down for a bit, not required
      # TODO: Remove this after some testing
      sleep 10
      break
    fi
    info "Waiting for cluster to be ready..."
    sleep 10
  done
}

fetch_token() {
  info "Fetching rke2 join token..."

  # Validate aws caller identity, fatal if not valid
  if ! aws sts get-caller-identity 2>/dev/null; then
    fatal "No valid aws caller identity"
  fi

  # Either
  #   a) fetch token from s3 bucket
  #   b) fail
  if token=$(aws s3 cp "s3://${token_bucket}/${token_object}" - 2>/dev/null);then
    info "Found token from s3 object"
  else
    fatal "Could not find cluster token from s3"
  fi

  echo "token: $${token}" >> "/etc/rancher/rke2/config.yaml"
}

upload() {
  # Wait for kubeconfig to exist, then upload to s3 bucket
  retries=10

  while [ ! -f /etc/rancher/rke2/rke2.yaml ]; do
    sleep 10
    if [ "$retries" = 0 ]; then
      fatal "Failed to create kubeconfig"
    fi
    (retries--)
  done

  # Upload to s3 bucket
  aws s3 cp /etc/rancher/rke2/rke2.yaml "s3://${token_bucket}/rke2.yaml"
}

pre_userdata() {
  info "Beginning user defined pre userdata"
  ${pre_userdata}
  info "Beginning user defined pre userdata"
}

post_userdata() {
  info "Beginning user defined post userdata"
  ${post_userdata}
  info "Ending user defined post userdata"
}

{
  pre_userdata

  config
  fetch_token

  if [ $CCM = "true" ]; then
    append_config 'cloud-provider-name: "aws"'
  fi

  if [ $TYPE = "server" ]; then
    # Initialize server
    identify

    cat <<EOF >> "/etc/rancher/rke2/config.yaml"
tls-san:
  - ${server_url}
EOF

    if [ $SERVER_TYPE = "server" ]; then
      append_config 'server: https://${server_url}:9345'
      # Wait for cluster to exist, then init another server
      cp_wait
    fi

    systemctl enable rke2-server
    systemctl daemon-reload
    systemctl start rke2-server

    export KUBECONFIG=/etc/rancher/rke2/rke2.yaml
    export PATH=$PATH:/var/lib/rancher/rke2/bin

    # Upload kubeconfig to s3 bucket
    upload

  else
    append_config 'server: https://${server_url}:9345'

    # Default to agent
    systemctl enable rke2-agent
    systemctl daemon-reload
    systemctl start rke2-agent
  fi

  post_userdata
}