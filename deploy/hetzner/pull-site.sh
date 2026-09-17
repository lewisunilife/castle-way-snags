#!/usr/bin/env bash
# Bring the served page up to date with the main branch. Runs every minute
# from the systemd timer; does nothing when nothing changed. The swap is a
# single file copy, so a visitor either gets the old page or the new one,
# never half of each.
set -euo pipefail

REPO_DIR="${REPO_DIR:-/opt/castle-way-snags}"
WEB_DIR="${WEB_DIR:-/var/www/castle-way-snags}"

cd "$REPO_DIR"
before="$(git rev-parse HEAD)"
git fetch -q origin main
git reset -q --hard origin/main
after="$(git rev-parse HEAD)"

if [ "$before" != "$after" ] || [ ! -f "$WEB_DIR/index.html" ]; then
  mkdir -p "$WEB_DIR"
  tmp="$WEB_DIR/.index.html.$$"
  cp site/index.html "$tmp"
  mv -f "$tmp" "$WEB_DIR/index.html"
  echo "castle-way-snags: published $after"
fi
