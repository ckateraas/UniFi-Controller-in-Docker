#!/usr/bin/env bash

UNIFI_INSTALLATION_DIR=/usr/lib/unifi
ROOT_DIR=/unifi
DATA_DIR="$ROOT_DIR/data"
LOG_DIR="$ROOT_DIR/logs"
CERT_DIR="$ROOT_DIR/cert"
BACKUP_DIR="$DATA_DIR/backup"
INIT_DIR=/init.d

log() {
    echo "$(date +"[%Y-%m-%d %T]") $*"
}

prepare_unifi_dir() {
    log "Fixing permissions for $ROOT_DIR"
    chown -R unifi:unifi "$ROOT_DIR"
    chmod 700 "$ROOT_DIR"
}

set_java_home() {
    log "JAVA_HOME is not set. Fixing!"
    JAVA_HOME=$(readlink -f "$(which java)" | sed "s|/jre/bin/java||")
    if [[ ! -d "$JAVA_HOME" ]]; then
        log "Tried to set JAVA_HOME to $JAVA_HOME, but it is not a directory!"
        exit 1
    fi
}

run_mounted_init_scripts() {
    if [[ -d "$INIT_DIR" ]]; then
        run-parts "$INIT_DIR"
    fi
}

check_uid_and_gid() {
    if [[ ! -z "$UNIFI_UID" && "$(id unifi -u)" != "$UNIFI_UID" ]]; then
        log "Changing UID of unifi user to $UNIFI_UID"
        usermod -o -u "$UNIFI_UID" unifi
    fi

    if [[ ! -z "$UNIFI_GID" ]] && [[ "$(id unifi -g)" != "$UNIFI_GID" ]]; then
        log "Changing GID of unifi group to $UNIFI_GID"
        groupmod -o -g "$UNIFI_GID" unifi
    fi
}

verify_directories_for_unifi_controller() {
    if [[ ! -d "$UNIFI_INSTALLATION_DIR/data" ]]; then
        log "Linking $DATA_DIR to $UNIFI_INSTALLATION_DIR/data"
        mkdir -p "$DATA_DIR"
        ln -s "$DATA_DIR" "$UNIFI_INSTALLATION_DIR"
    fi
    if [[ ! -d "$UNIFI_INSTALLATION_DIR/logs" ]]; then
        log "Linking $LOG_DIR to $UNIFI_INSTALLATION_DIR/logs"
        mkdir -p "$LOG_DIR"
        ln -s "$LOG_DIR" "$UNIFI_INSTALLATION_DIR"
    fi
    if [[ ! -d "$CERT_DIR" ]]; then
        log "Creating $CERT_DIR"
        mkdir -p "$CERT_DIR"
    fi
    if [[ ! -d "$UNIFI_INSTALLATION_DIR/backup" ]]; then
        log "Linking $BACKUP_DIR"
        mkdir -p "$BACKUP_DIR"
        ln -s "$BACKUP_DIR" "$UNIFI_INSTALLATION_DIR"
    fi
}

move_properties_file() {
    # Work around that Docker Compose does not allow you to set owner of volumes
    # so /unifi/system.properties will, most likely, be owned by 1000:1000.
    # And if placed in /unifi/data/system.properties, then /unifi/data will be auto
    # created by Docker Compose and owned by root:root.
    if [[ -f /system.properties ]]; then
        cp /system.properties /unifi/data/system.properties
    fi
}

create_jvm_options() {
    JVM_MAX_HEAP_SIZE=${JVM_MAX_HEAP_SIZE-1G}
    JVM_OPTS="-Xmx$JVM_MAX_HEAP_SIZE"
    if [[ ! -z "$JVM_INIT_HEAP_SIZE" ]]; then
        JVM_OPTS="$JVM_OPTS -Xms$JVM_INIT_HEAP_SIZE"
    fi

    if [[ ! -z "$JVM_MAX_THREAD_STACK_SIZE" ]]; then
        JVM_OPTS="$JVM_OPTS -Xss$JVM_MAX_THREAD_STACK_SIZE"
    fi

    JVM_OPTS="$JVM_OPTS -Djava.awt.headless=true -Dfile.encoding=UTF-8 -Dunifi.datadir=$DATA_DIR -Dunifi.logdir=$LOG_DIR"
}

start_unifi_controller() {
    log 'Starting UniFi Controller'
    set -x
    java $JVM_OPTS -jar "$UNIFI_INSTALLATION_DIR"/lib/ace.jar start
}

exit_handler() {
    log "Exit signal received. Shutting down"
    java -jar "$UNIFI_INSTALLATION_DIR"/lib/ace.jar stop
}