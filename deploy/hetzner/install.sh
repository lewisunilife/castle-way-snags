#!/usr/bin/env bash
# One-time setup on a Debian/Ubuntu Hetzner box. Run as root:
#
#   SNAGS_HOST=snags.unilife.co.uk bash install.sh
#
# Leave SNAGS_HOST unset to serve plain HTTP on the server's address until
# the DNS record exists; run it again with the host set once it does.
#
# What it puts in place:
#   /opt/castle-way-snags          a clone of the repo, pulled every minute
#   /var/www/castle-way-snags      the page Caddy serves
#   /var/backups/castle-way-snags  nightly JSON copies of the two tables
#   castle-way-pull.timer          the minute-by-minute pull
#   castle-way-backup.timer        the 02:30 backup
set -euo pipefail

REPO_URL="${REPO_URL:-https://github.com/lewisunilife/castle-way-snags.git}"
SNAGS_HOST="${SNAGS_HOST:-}"
REPO_DIR=/opt/castle-way-snags
WEB_DIR=/var/www/castle-way-snags

export DEBIAN_FRONTEND=noninteractive
apt-get update -q
apt-get install -y -q git curl python3 debian-keyring debian-archive-keyring apt-transport-https

if ! command -v caddy >/dev/null; then
  curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
  curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' > /etc/apt/sources.list.d/caddy-stable.list
  apt-get update -q
  apt-get install -y -q caddy
fi

if [ ! -d "$REPO_DIR/.git" ]; then
  git clone -q "$REPO_URL" "$REPO_DIR"
fi
cd "$REPO_DIR"
git fetch -q origin main && git reset -q --hard origin/main

install -m 755 deploy/hetzner/pull-site.sh /usr/local/bin/castle-way-pull
install -m 755 deploy/hetzner/backup-supabase.sh /usr/local/bin/castle-way-backup

# Caddy: the host goes in as an environment variable the Caddyfile reads.
install -m 644 deploy/hetzner/Caddyfile /etc/caddy/Caddyfile
mkdir -p /etc/systemd/system/caddy.service.d
cat > /etc/systemd/system/caddy.service.d/castle-way.conf <<UNIT
[Service]
Environment=SNAGS_HOST=$SNAGS_HOST
UNIT

cat > /etc/systemd/system/castle-way-pull.service <<'UNIT'
[Unit]
Description=Castle Way snagging list: pull the latest page from GitHub

[Service]
Type=oneshot
ExecStart=/usr/local/bin/castle-way-pull
UNIT

cat > /etc/systemd/system/castle-way-pull.timer <<'UNIT'
[Unit]
Description=Castle Way snagging list: pull every minute

[Timer]
OnBootSec=30s
OnUnitActiveSec=60s
AccuracySec=5s

[Install]
WantedBy=timers.target
UNIT

cat > /etc/systemd/system/castle-way-backup.service <<'UNIT'
[Unit]
Description=Castle Way snagging list: nightly copy of the Supabase tables

[Service]
Type=oneshot
ExecStart=/usr/local/bin/castle-way-backup
UNIT

cat > /etc/systemd/system/castle-way-backup.timer <<'UNIT'
[Unit]
Description=Castle Way snagging list: back up at 02:30 every night

[Timer]
OnCalendar=*-*-* 02:30:00
Persistent=true

[Install]
WantedBy=timers.target
UNIT

systemctl daemon-reload
/usr/local/bin/castle-way-pull
systemctl enable --now castle-way-pull.timer castle-way-backup.timer
systemctl restart caddy
/usr/local/bin/castle-way-backup || echo "first backup failed; check network and try: castle-way-backup"

echo
if [ -n "$SNAGS_HOST" ]; then
  echo "Serving https://$SNAGS_HOST/  (Tower 2: https://$SNAGS_HOST/?tower=2)"
else
  echo "Serving http://$(curl -s -4 ifconfig.me || hostname -I | awk '{print $1}')/  (set SNAGS_HOST and rerun for HTTPS)"
fi
echo "Backups: /var/backups/castle-way-snags/   Pull log: journalctl -u castle-way-pull"
