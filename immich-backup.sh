#!/bin/bash
set -euo pipefail

BACKUP_ROOT="/mnt/nas-data"
STACKS_ROOT="/opt/stacks"
TMP_DIR="/tmp/service-dumps"
DATE=$(date +"%Y-%m-%d_%H-%M-%S")
B2_REMOTE="bb-b2:dazza9905-nas-data"
mkdir -p "$TMP_DIR"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color
log() { echo -e "${GREEN}[$(date +'%H:%M:%S')]${NC} $1"; }
warn() { echo -e "${YELLOW}[$(date +'%H:%M:%S')] WARN:${NC} $1"; }

############################################
# 1. Immich DB Backup 
############################################
log "Starting Immich DB dump..."

docker exec -t immich_postgres \
  pg_dumpall --clean --if-exists --username="postgres" \
  | gzip > "$TMP_DIR/immich-$DATE.sql.gz"

if [ -f "$TMP_DIR/immich-$DATE.sql.gz" ]; then
    log "DB Dump created successfully: $(du -h "$TMP_DIR/immich-$DATE.sql.gz" | cut -f1)"
else
    warn "DB Dump file not found!"
    exit 1
fi

############################################
# 2. Stopping Immich
############################################
log "Stopping Immich application containers to ensure data consistency..."
docker compose -f "$STACKS_ROOT/immich/compose.yaml" stop

############################################
# 3. Immich Library Backup
############################################
log "Backing up Immich filesystem data..."

DELETED_DATE=$(date +%Y-%m-%d)

# Note: Using --dry-run as per your snippet. Remove it to actually sync.
rclone sync "/mnt/nas-data/immich-app/data" "$B2_REMOTE/immich/data" \
  --backup-dir "$B2_REMOTE/immich/deleted-data" \
  --transfers 32 \
  --checkers 32 \
  --fast-list \
  --b2-chunk-size 64M \
  --b2-upload-cutoff 64M \
  --buffer-size 64M \
  --progress

############################################
# 4. Restarting Immich
############################################
log "Restarting Immich application containers..."
docker compose -f "$STACKS_ROOT/immich/compose.yaml" start

############################################
# 5. Upload DB dumps
############################################
log "Uploading DB dumps to B2..."

sudo -u "dazza" bash <<EOF
rclone copy "$TMP_DIR" "$B2_REMOTE/immich/db-dumps" --progress
EOF

echo "All dumps uploaded"

############################################
# 6. Cleanup
############################################
log "Cleaning up temporary files..."
rm -rf "$TMP_DIR"

log "Backup process completed successfully."
