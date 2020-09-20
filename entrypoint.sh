#! /usr/bin/env bash

set -e

source /functions.sh

trap 'kill ${!}; exit_handler' SIGHUP SIGINT SIGQUIT SIGTERM

# First startup is as root, to set correct GID and UID on the /unifi mount
if [[ "$EUID" -eq 0 ]]; then
  check_uid_and_gid
  prepare_unifi_dir
  log "Restarting as Unifi user"
  runuser -u unifi -g unifi --preserve-environment /entrypoint.sh
fi

if [[ -z "${JAVA_HOME}" ]]; then
  set_java_home
fi

verify_directories_for_unifi_controller

run_mounted_init_scripts

if [[ $# -gt 0 ]]; then
    log "Running ad-hoc command: $*"
    exec "${@}"
fi

move_properties_file
create_jvm_options
start_unifi_controller
