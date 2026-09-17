#!/usr/bin/env bash
# Nightly copy of the two Supabase tables to this server's disk, as JSON.
#
# The page's publishable key can read both tables (that is what the page
# does), so no secret is needed: the URL and key are read off the page
# itself unless SUPABASE_URL and SUPABASE_KEY are set. Rows come down in
# pages of 1000, so the copy is complete however long the record grows.
# Copies are kept for KEEP_DAYS (default 90) and never leave this machine.
set -euo pipefail

REPO_DIR="${REPO_DIR:-/opt/castle-way-snags}"
BACKUP_DIR="${BACKUP_DIR:-/var/backups/castle-way-snags}"
KEEP_DAYS="${KEEP_DAYS:-90}"
PAGE="$REPO_DIR/site/index.html"

SUPABASE_URL="${SUPABASE_URL:-$(grep -o 'https://[a-z0-9]*\.supabase\.co' "$PAGE" | head -1)}"
SUPABASE_KEY="${SUPABASE_KEY:-$(grep -o 'sb_publishable_[A-Za-z0-9_-]*' "$PAGE" | head -1)}"
if [ -z "$SUPABASE_URL" ] || [ -z "$SUPABASE_KEY" ]; then
  echo "could not find the Supabase URL and key" >&2
  exit 1
fi

stamp="$(date -u +%Y-%m-%dT%H%M%SZ)"
dir="$BACKUP_DIR/$stamp"
mkdir -p "$dir"
chmod 700 "$BACKUP_DIR"

fetch_table() {
  local table="$1" out="$2" from=0 size=1000 got
  echo "[" > "$out.tmp"
  local first=1
  while :; do
    local to=$((from + size - 1))
    local chunk
    chunk="$(curl -sS --fail --max-time 60 \
      -H "apikey: $SUPABASE_KEY" -H "Authorization: Bearer $SUPABASE_KEY" \
      -H "Range-Unit: items" -H "Range: $from-$to" \
      "$SUPABASE_URL/rest/v1/$table?select=*&order=id")"
    got="$(printf '%s' "$chunk" | python3 -c 'import json,sys; print(len(json.load(sys.stdin)))')"
    if [ "$got" -gt 0 ]; then
      [ "$first" = 1 ] || echo "," >> "$out.tmp"
      first=0
      printf '%s' "$chunk" | python3 -c 'import json,sys; rows=json.load(sys.stdin); print(",".join(json.dumps(r) for r in rows))' >> "$out.tmp"
    fi
    [ "$got" -lt "$size" ] && break
    from=$((from + size))
  done
  echo "]" >> "$out.tmp"
  python3 -c 'import json,sys; json.load(open(sys.argv[1]))' "$out.tmp"   # a valid file or nothing
  mv -f "$out.tmp" "$out"
}

fetch_table castle_way_snags "$dir/castle_way_snags.json"
fetch_table castle_way_comments "$dir/castle_way_comments.json"

snags="$(python3 -c 'import json,sys; print(len(json.load(open(sys.argv[1]))))' "$dir/castle_way_snags.json")"
comments="$(python3 -c 'import json,sys; print(len(json.load(open(sys.argv[1]))))' "$dir/castle_way_comments.json")"
echo "castle-way-snags backup $stamp: $snags snag rows, $comments comment rows -> $dir"

# Sweep old copies.
find "$BACKUP_DIR" -mindepth 1 -maxdepth 1 -type d -mtime +"$KEEP_DAYS" -exec rm -rf {} +
