#!/usr/bin/env bash
set -euo pipefail

TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
STAGING_DIR="/srv/backups"
ARCHIVE="${STAGING_DIR}/linux-cloud-backup-${TIMESTAMP}.tar.gz"
CHECKSUM="${ARCHIVE}.sha256"
LOG_FILE="/var/log/linux-cloud-foundation/backup.log"

log() {
    printf '%s %s\n' "$(date --iso-8601=seconds)" "$*" | tee -a "$LOG_FILE"
}

mkdir -p "$STAGING_DIR"
touch "$LOG_FILE"
chmod 640 "$LOG_FILE"

log "INFO: starting backup"

TEMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TEMP_DIR"' EXIT

mkdir -p \
    "${TEMP_DIR}/usr/share/nginx/html" \
    "${TEMP_DIR}/etc/nginx/conf.d" \
    "${TEMP_DIR}/usr/local/sbin" \
    "${TEMP_DIR}/etc/systemd/system"

cp -a /usr/share/nginx/html/. "${TEMP_DIR}/usr/share/nginx/html/"
cp -a /etc/nginx/conf.d/myserver.test.conf "${TEMP_DIR}/etc/nginx/conf.d/"
cp -a /usr/local/sbin/disk-check.sh "${TEMP_DIR}/usr/local/sbin/"
cp -a /etc/systemd/system/project-diskcheck.service "${TEMP_DIR}/etc/systemd/system/"
cp -a /etc/systemd/system/project-diskcheck.timer "${TEMP_DIR}/etc/systemd/system/"

tar -czf "$ARCHIVE" -C "$TEMP_DIR" .

sha256sum "$ARCHIVE" > "$CHECKSUM"

chown root:webadmin "$ARCHIVE" "$CHECKSUM"
chmod 640 "$ARCHIVE" "$CHECKSUM"

log "INFO: created archive ${ARCHIVE}"
log "INFO: created checksum ${CHECKSUM}"
log "INFO: backup completed successfully"
