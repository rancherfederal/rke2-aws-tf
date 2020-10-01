#!/bin/bash
set -e

build_config() {
  mkdir -p "/etc/rancher/rke2"
  cat <<-EOF > "/etc/rancher/rke2/config.yaml"
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
EOF
}

{
  build_config
}