#!/usr/bin/env bash
set -euo pipefail

PRIVATE_REPO="git@github.com:nicocapalbo/Homelab-private.git"
ROOT="$(cd "$(dirname "$0")" && pwd)"
PRIVATE_DIR="$ROOT/../Homelab-private"
STAMP="$(git -C "$ROOT" rev-parse --absolute-git-dir)/last-sync"
RSYNC_IMAGE="homelab-rsync:local"

# Root container rsync: appdata has root-owned dirs (created by containers)
# that a plain user rsync cannot read, which silently breaks --delete and
# makes rsync exit 23 (killing this script before the commit step).
if ! docker image inspect "$RSYNC_IMAGE" >/dev/null 2>&1; then
  echo "Building rsync helper image..."
  docker build -t "$RSYNC_IMAGE" - <<'EOF'
FROM alpine
RUN apk add --no-cache rsync
EOF
fi

if [ ! -d "$PRIVATE_DIR" ]; then
  echo "Cloning private config repo..."
  git clone "$PRIVATE_REPO" "$PRIVATE_DIR"
fi

echo "Copying .env..."
cp "$ROOT/.env" "$PRIVATE_DIR/"

echo "Syncing appdata configs..."
rc=0
docker run --rm \
  -v "$ROOT/appdata:/src:ro" \
  -v "$PRIVATE_DIR/appdata:/dst" \
  "$RSYNC_IMAGE" rsync -a -m --delete --delete-excluded \
    --include='/hermes/.env' \
    --include='/hermes/skills/' \
    --include='/homepage/' \
    --include='/nginx/' \
    --include='/hermes/' \
    --exclude='/hermes/*' \
    --exclude='/*' \
    --include='*/' \
    --include='*.json' --include='*.yaml' --include='*.yml' \
    --include='*.ini' --include='*.conf' --include='*.toml' \
    --include='*.xml' --include='*.key' --include='*.pub' \
    --include='*.pem' --include='*.crt' --include='*.env' \
    --include='*.css' --include='*.js' --include='*.lock' \
    --include='*.md' --include='*.txt' --include='*.cfg' \
    --include='*.plist' --include='.gitignore' \
    --exclude='*' \
    /src/ /dst/ || rc=$?

# 23 = partial transfer (unreadable files), 24 = source files vanished
# mid-transfer. Anything else is a real failure.
if [ "$rc" -ne 0 ] && [ "$rc" -ne 23 ] && [ "$rc" -ne 24 ]; then
  echo "rsync failed with exit code $rc" >&2
  exit "$rc"
fi

echo "Fixing ownership..."
docker run --rm -v "$PRIVATE_DIR:/repo" "$RSYNC_IMAGE" \
  sh -c 'chown -R 1000:1000 /repo'

echo "Committing and pushing..."
cd "$PRIVATE_DIR"
git add -A
if git diff --cached --quiet; then
  echo "No changes to sync."
else
  git commit -m "sync configs $(date +%Y-%m-%d)"
  git push
  echo "Sync complete."
fi

date +%s > "$STAMP"
