#!/usr/bin/env bash
set -euo pipefail

PRIVATE_REPO="git@github.com:nicocapalbo/Homelab-private.git"
PRIVATE_DIR="$(cd "$(dirname "$0")" && pwd)/../Homelab-private"

if [ ! -d "$PRIVATE_DIR" ]; then
  echo "Cloning private config repo..."
  git clone "$PRIVATE_REPO" "$PRIVATE_DIR"
fi

echo "Copying .env..."
cp .env "$PRIVATE_DIR/"

echo "Syncing appdata configs..."
rsync -a -m --delete \
  --include='*/' \
  --include='*.json' --include='*.yaml' --include='*.yml' \
  --include='*.ini' --include='*.conf' --include='*.toml' \
  --include='*.xml' --include='*.key' --include='*.pub' \
  --include='*.pem' --include='*.crt' --include='*.env' \
  --include='*.css' --include='*.js' --include='*.lock' \
  --include='*.md' --include='*.txt' --include='*.cfg' \
  --include='*.plist' --include='.gitignore' \
  --include='.migrate' --include='.HA_VERSION' \
  --include='.storage' --include='.cloud' \
  --exclude='*' \
  appdata/ "$PRIVATE_DIR/appdata/"

echo "Committing and pushing..."
cd "$PRIVATE_DIR"
if git diff --quiet && git diff --cached --quiet; then
  echo "No changes to sync."
else
  git add -A
  git commit -m "sync configs $(date +%Y-%m-%d)"
  git push
  echo "Sync complete."
fi
