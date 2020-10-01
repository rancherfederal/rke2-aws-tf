#!/bin/bash

cp_wait() {
  while true; do
    timeout 1 bash -c "cat < /dev/null > /dev/tcp/${server_lb}/6443"
    if [ "$?" == 0 ]; then
      echo "leader is ready"
      break
    fi
    echo "waiting for leader to be ready..."
    sleep 10
  done
}

build_config() {
  mkdir -p "/etc/rancher/rke2"
  cat <<-EOF > "/etc/rancher/rke2/config.yaml"
%{~ if server_index == 0 }
cluster-init: true
%{~ else }
server: "https://${server_lb}:9345"
%{~ endif }

# args
%{~ for k, v in args }
${k}: "${v}"
%{~ endfor }

# arg sets
%{~ for k, v in list_args }
%{~ if length(v) > 0 }
${k}:
  %{~ for _ in v }
  - "${_}"
  %{~ endfor }
%{~ endif }
%{~ endfor }

${config}
EOF
}

{
  %{~ if server_index != 0 }
  cp_wait
  %{~ endif }

  build_config
}