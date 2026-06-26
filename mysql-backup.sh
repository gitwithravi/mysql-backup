#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${1:-./backup.conf}"
RETENTION_DAYS=3

die() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || die "Required command not found: $1"
}

require_config() {
  local name="$1"
  local value="${!name:-}"

  [[ -n "$value" ]] || die "Missing required config value: $name"
}

quote_remote_path() {
  local path="$1"

  printf "%q" "$path"
}

[[ -f "$CONFIG_FILE" ]] || die "Config file not found: $CONFIG_FILE"

# shellcheck disable=SC1090
source "$CONFIG_FILE"

require_command mysqldump
require_command gzip
require_command scp
require_command find
require_command mkdir
require_command date

require_config DB_HOST
require_config DB_PORT
require_config DB_NAME
require_config DB_USER
require_config DB_PASSWORD
require_config LOCAL_BACKUP_DIR
require_config REMOTE_USER
require_config REMOTE_HOST
require_config REMOTE_PORT
require_config REMOTE_BACKUP_DIR

mkdir -p "$LOCAL_BACKUP_DIR"

timestamp="$(date '+%Y%m%d_%H%M%S')"
backup_file="${DB_NAME}_${timestamp}.sql.gz"
backup_path="${LOCAL_BACKUP_DIR%/}/${backup_file}"

printf 'Creating backup: %s\n' "$backup_path"

MYSQL_PWD="$DB_PASSWORD" mysqldump \
  --host="$DB_HOST" \
  --port="$DB_PORT" \
  --user="$DB_USER" \
  --single-transaction \
  --routines \
  --triggers \
  --events \
  "$DB_NAME" | gzip >"$backup_path"

scp_args=(-P "$REMOTE_PORT")

if [[ -n "${SSH_KEY_PATH:-}" ]]; then
  scp_args+=(-i "$SSH_KEY_PATH")
fi

remote_target="${REMOTE_USER}@${REMOTE_HOST}:$(quote_remote_path "${REMOTE_BACKUP_DIR%/}/")"

printf 'Copying backup to remote: %s@%s:%s\n' "$REMOTE_USER" "$REMOTE_HOST" "${REMOTE_BACKUP_DIR%/}/"
scp "${scp_args[@]}" "$backup_path" "$remote_target"

printf 'Removing local backups older than %s days from %s\n' "$RETENTION_DAYS" "$LOCAL_BACKUP_DIR"
find "$LOCAL_BACKUP_DIR" \
  -maxdepth 1 \
  -type f \
  -name "${DB_NAME}_*.sql.gz" \
  -mtime +"$RETENTION_DAYS" \
  -print \
  -delete

printf 'Backup completed successfully: %s\n' "$backup_file"
