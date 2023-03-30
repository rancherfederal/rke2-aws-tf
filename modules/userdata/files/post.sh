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

post_userdata() {
  info "Beginning user defined post userdata"
  ${post_userdata}
  info "Ending user defined post userdata"
}

{
  post_userdata
}
