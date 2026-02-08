#!/bin/bash
set eu -o pipefail
BASE_DIR="/var/log/rsyslog"

LOCAL_SEVS=("info" "notice")

SHIP_SEVS=("warning" "err" "crit" "alert" "emerg")

SYSLOG_SEVS=("${SHIP_SEVS[@]}" "${LOCAL_SEVS[@]}")

DATE=$(date -d "yesterday" +"%Y-%m-%d")

DATE_DIR="${DATE//-//}"

RETENTION_LOCAL_ONLY_DAYS=15

RETENTION_SHIP_LOCAL_DAYS=30

GZIP_LEVEL=6

S3_BUCKET="${S3_BUCKET:-}"

S3_BUCKET_SHORT="${S3_BUCKET_SHORT:-}"

S3_PREFIX="${S3_PREFIX:-rsyslog}"

log() { printf '[%s] %s\n' "$(date -Is)" "$*"; }

compress_severity_tree() {
  local sev="$1"
  local date="$2"
  local dir="${BASE_DIR}/${sev}/${DATE_DIR}"
  [ -d "$dir" ] || return 0
  log "Compressing severity '${sev}' under: ${dir}"
  cd "$dir"
  find . -maxdepth 1 -type d ! -name '.' -printf '%P\n' -exec sh -c 'tar -czf "$1.tar.gz" $1 --remove-files --warning=no-file-removed' _ {} \;
}
for sev in "${SYSLOG_SEVS[@]}"; do
  compress_severity_tree "$sev" "${DATE_DIR}"
done

if [[ -n "$S3_BUCKET" && -n "$S3_BUCKET_SHORT" ]]; then
  for sev in "${SHIP_SEVS[@]}"; do
    src="${BASE_DIR}/${sev}/${DATE_DIR}"
    [ -d "$src" ] || continue
    if [[ "${sev}" -eq "warning" || "${sev}" -eq "err" ]]; then
    	dest="s3://${S3_BUCKET_SHORT}/${S3_PREFIX}/${sev}/${DATE_DIR}"
    else
    	dest="s3://${S3_BUCKET}/${S3_PREFIX}/${sev}/${DATE_DIR}"
    fi
    log "Sync to S3: ${src} -> ${dest} (only *.tar.gz)"
    aws s3 sync "$src" "$dest" --exclude "*" --include "*.tar.gz"
  done
else
  log "S3_BUCKET OR S3_BUCKET_SHORT not set; skipping S3 sync. (export S3_BUCKET=... to enable)"
fi

delete_older_than_days() {
  local sev="$1"
  local days="$2"
  local dir="${BASE_DIR}/${sev}"
  [ -d "$dir" ] || return 0
  log "Applying retention: severity='${sev}', delete files older than ${days} days in ${dir}"
  find "$dir" -type f -mtime +"$days" -print0 | xargs -0 -r rm -f
  find "$dir" -type d -empty -print0 | xargs -0 -r rmdir 2>/dev/null || true
}
for sev in "${LOCAL_SEVS[@]}"; do
  delete_older_than_days "$sev" "$RETENTION_LOCAL_ONLY_DAYS"
done
for sev in "${SHIP_SEVS[@]}"; do
  delete_older_than_days "$sev" "$RETENTION_SHIP_LOCAL_DAYS"
done
log "Done."
