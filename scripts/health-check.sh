#!/usr/bin/env bash
set -euo pipefail

LOG_FILE="/var/log/linux-cloud-foundation/health-check.log"
HEALTH_URL="https://localhost/health"

log() {
    printf '%s %s\n' "$(date --iso-8601=seconds)" "$*" | tee -a "$LOG_FILE"
}

mkdir -p "$(dirname "$LOG_FILE")"
touch "$LOG_FILE"
chmod 640 "$LOG_FILE"

if curl -kfsS "$HEALTH_URL" >/dev/null 2>&1; then
    log "OK: NGINX health check passed"
    exit 0
fi

log "WARNING: NGINX health check failed"

if systemctl is-active --quiet nginx; then
    log "INFO: NGINX service is active; no restart attempted"
    exit 1
fi

log "INFO: attempting controlled NGINX restart"
systemctl restart nginx

sleep 5

if curl -kfsS "$HEALTH_URL" >/dev/null 2>&1; then
    log "OK: NGINX recovered after restart"
    exit 0
fi

log "ERROR: NGINX still unhealthy after restart"
exit 2
