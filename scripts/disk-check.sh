#!/usr/bin/env bash
set -euo pipefail

LOG_FILE="/var/log/linux-cloud-foundation/disk-check.log"
THRESHOLD=80
MOUNTPOINTS=("/" "/srv")

mkdir -p "$(dirname "$LOG_FILE")"
touch "$LOG_FILE"
chmod 640 "$LOG_FILE"

log() {
    printf '%s %s\n' "$(date --iso-8601=seconds)" "$*" | tee -a "$LOG_FILE"
}

exit_code=0

for mountpoint in "${MOUNTPOINTS[@]}"; do
    if ! mountpoint -q "$mountpoint"; then
        log "ERROR: mountpoint ${mountpoint} is not mounted"
        exit_code=2
        continue
    fi

    usage="$(df --output=pcent "$mountpoint" | tail -n 1 | tr -dc '0-9')"
    available="$(df -h --output=avail "$mountpoint" | tail -n 1 | tr -d ' ')"

    if (( usage >= THRESHOLD )); then
        log "WARNING: ${mountpoint} usage is ${usage}% (available: ${available}); threshold is ${THRESHOLD}%"
        exit_code=1
    else
        log "OK: ${mountpoint} usage is ${usage}% (available: ${available})"
    fi
done

exit "$exit_code"
