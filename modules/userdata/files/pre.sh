#!/bin/sh

export TYPE="${type}"
export CCM="${ccm}"

# info logs the given argument at info log level.
info() {
    echo "[INFO] " "$@"
}

timestamp() {
  date "+%Y-%m-%d %H:%M:%S"
}

pre_userdata() {
  info "Beginning user defined pre userdata"
  ${pre_userdata}
  info "Ending user defined pre userdata"
}

{
  pre_userdata
}