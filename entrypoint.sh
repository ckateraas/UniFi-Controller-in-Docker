#! /usr/bin/env bash

set -e

source /functions.sh

trap 'kill ${!}; exit_handler' SIGHUP SIGINT SIGQUIT SIGTERM

if [[ -z "${JAVA_HOME}" ]]; then
  log "JAVA_HOME is not set. Fixing!"
  set_java_home
fi

check_uid_and_gid
verify_directories_for_unifi_controller

run_mounted_init_scripts

if [[ $# -gt 0 ]]; then
    log "Running ad-hoc command: $*"
    exec "${@}"
fi

move_properties_file
create_jvm_options
start_unifi_controller
