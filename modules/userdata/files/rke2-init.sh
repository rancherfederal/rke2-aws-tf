#!/bin/sh

export TYPE="${type}"
export CCM="${ccm}"
export IS_LEADER="${is_leader}"

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

timestamp() {
  date "+%Y-%m-%d %H:%M:%S"
}

config() {
  mkdir -p "/etc/rancher/rke2"
  cat <<EOF > "/etc/rancher/rke2/config.yaml"
# Additional user defined configuration
${config}
EOF
}

append_config() {
  echo "$1" >> "/etc/rancher/rke2/config.yaml"
}

elect_monitor() {
  # Fetch other running instances in ASG
  TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
  instance_id=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id)
  asg_name=$(aws autoscaling describe-auto-scaling-instances --instance-ids "$instance_id" --query 'AutoScalingInstances[*].AutoScalingGroupName' --output text)
  instances=$(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-name "$asg_name" --query 'AutoScalingGroups[*].Instances[?HealthStatus==`Healthy`].InstanceId' --output text)

  # Select the monitoring node as the last of the instance ids sorted alphanumerically
  monitor=$(echo $instances | tr ' ' '\n' | sort -n | tail -n1)
  monitor_ip=$(aws ec2 describe-instances --instance-ids "$monitor" --query 'Reservations[*].Instances[*].[PrivateIpAddress]' --output text)

  info "Current instance: $instance_id | Monitor instance: $monitor"

  if [ "$instance_id" = "$monitor" ]; then
    MONITOR=true
    info "Electing as dedicated monitor"
    append_config 'node-taint: monitoring=yes:NoSchedule'
    append_config 'node-label: monitoring=yes'
  fi
  info "Electing as joining agent"
}

mark_monitor() {
  export KUBECONFIG=/etc/rancher/rke2/rke2.yaml
  export PATH=$PATH:/var/lib/rancher/rke2/bin
  info "Tainting and labelling monitor node: $monitor  $monitor_ip"
  k8s_monitor=$(kubectl get nodes --no-headers -o=custom-columns="NAME:.metadata.name" | grep $monitor_ip)
  kubectl taint nodes $k8s_monitor monitoring=yes:NoSchedule
  kubectl label nodes $k8s_monitor monitoring=yes
}

identify() {
  # Default to server
  SERVER_TYPE="server"

  TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
  supervisor_status=$(curl --write-out '%%{http_code}' -sk --output /dev/null https://${server_url}:9345/ping)

  if [ "$supervisor_status" -eq 200 ]; then
    info "API server available, identifying as server joining existing cluster"
  fi
}

cp_wait() {
  while true; do
    supervisor_status=$(curl --write-out '%%{http_code}' -sk --output /dev/null https://${server_url}:9345/ping)
    if [ "$supervisor_status" -eq 200 ]; then
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

local_cp_api_wait() {
  export PATH=$PATH:/var/lib/rancher/rke2/bin
  export KUBECONFIG=/etc/rancher/rke2/rke2.yaml

  while true; do
    info "$(timestamp) Waiting for kube-apiserver..."
    if timeout 1 bash -c "true <>/dev/tcp/localhost/6443" 2>/dev/null; then
        break
    fi
    sleep 5
  done

  wait $!

  nodereadypath='{range .items[*]}{@.metadata.name}:{range @.status.conditions[*]}{@.type}={@.status};{end}{end}'
  until kubectl get nodes --selector='node-role.kubernetes.io/master' -o jsonpath="$nodereadypath" | grep -E "Ready=True"; do
    info "$(timestamp) Waiting for servers to be ready..."
    sleep 5
  done

  info "$(timestamp) all kube-system deployments are ready!"
}

fetch_token() {
  info "Fetching rke2 join token..."

  TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
  aws configure set default.region "$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/placement/region)"

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
    ((retries--))
  done

  # Replace localhost with server url and upload to s3 bucket
  sed "s/127.0.0.1/${server_url}/g" /etc/rancher/rke2/rke2.yaml | aws s3 cp - "s3://${token_bucket}/rke2.yaml" --content-type "text/yaml"
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

    cat <<EOF >> "/etc/rancher/rke2/config.yaml"
tls-san:
  - ${server_url}
EOF

    if [ $TYPE = "server" ] && [ $IS_LEADER = "false" ]; then     # additional server joining an existing cluster
        # Initialize server
      identify
      append_config 'server: https://${server_url}:9345'
      # Wait for cluster to exist, then init another server
      cp_wait
    fi

    systemctl enable rke2-server
    systemctl daemon-reload
    systemctl start rke2-server

    export KUBECONFIG=/etc/rancher/rke2/rke2.yaml
    export PATH=$PATH:/var/lib/rancher/rke2/bin

    if [ $IS_LEADER = "true" ]; then
      # Upload kubeconfig to s3 bucket
      upload

      # For servers, wait for apiserver to be ready before continuing so that `post_userdata` can operate on the cluster
      local_cp_api_wait
    fi

  else
    append_config 'server: https://${server_url}:9345'
    # elect_monitor
    # Default to agent
    systemctl enable rke2-agent
    systemctl daemon-reload
    systemctl start rke2-agent
  fi

  post_userdata
}
