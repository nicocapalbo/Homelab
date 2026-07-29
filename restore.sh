#!/usr/bin/env bash
set -euo pipefail

PRIVATE_REPO="git@github.com:nicocapalbo/Homelab-private.git"

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

echo "Cloning private config repo..."
git clone --depth=1 "$PRIVATE_REPO" "$TMP_DIR"

echo "Copying .env..."
cp "$TMP_DIR/.env" .

echo "Copying appdata configs..."
rsync -a --info=progress2 \
  --exclude='*.db' --exclude='*.sqlite' --exclude='*.sqlite3' \
  --exclude='*.db-shm' --exclude='*.db-wal' \
  --exclude='*.pkl' --exclude='*.pickle' \
  --exclude='*.log' --exclude='*.gz' \
  --exclude='*.blob' \
  --exclude='cache/' --exclude='Cache/' --exclude='.cache/' \
  --exclude='log/' --exclude='logs/' --exclude='Logs/' \
  --exclude='__pycache__/' --exclude='*.pyc' \
  --exclude='node_modules/' --exclude='.pnpm-store/' --exclude='.yarn-cache/' \
  --exclude='.nuget/' --exclude='.dotnet-sdk/' \
  --exclude='backups/' --exclude='dump.rdb' \
  "$TMP_DIR/appdata/" appdata/

echo ""
echo "Restore complete! Starting stack..."
docker compose up -d
