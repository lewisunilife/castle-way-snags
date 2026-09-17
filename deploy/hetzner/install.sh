#!/usr/bin/env bash
# One-time setup on a Debian/Ubuntu Hetzner box. Run as root:
#
#   SNAGS_HOST=snags.unilife.co.uk bash install.sh
#
# The box may already be serving something else on port 80, so this looks
# before it touches anything:
#   nothing on port 80         -> Caddy serves the page (HTTPS itself when a
#                                 host is given, plain HTTP on the address
#                                 when not)
#   nginx already on port 80   -> a server block for SNAGS_HOST, alongside
#                                 whatever nginx serves already; certbot adds
#                                 HTTPS when CERT_EMAIL is set
#   apache already on port 80  -> the same, as an apache vhost
#   anything else on port 80   -> stops and says what it found
# With nginx or apache present a host name is required, since the page
# cannot take over the address they already answer on.
#
# Whatever serves it, the rest is the same:
#   /opt/castle-way-snags          a clone of the repo, pulled every minute
#   /var/www/castle-way-snags      the page that is served
#   /var/backups/castle-way-snags  nightly JSON copies of the two tables
#   castle-way-pull.timer          the minute-by-minute pull
#   castle-way-backup.timer        the 02:30 backup
set -euo pipefail

REPO_URL="${REPO_URL:-https://github.com/lewisunilife/castle-way-snags.git}"
SNAGS_HOST="${SNAGS_HOST:-}"
CERT_EMAIL="${CERT_EMAIL:-}"
REPO_DIR=/opt/castle-way-snags
WEB_DIR=/var/www/castle-way-snags

if [ "$(id -u)" != 0 ]; then echo "run as root" >&2; exit 1; fi

export DEBIAN_FRONTEND=noninteractive
apt-get update -q
apt-get install -y -q git curl python3 ca-certificates

# ---- what already answers on port 80? --------------------------------------
listener="$(ss -ltnp 2>/dev/null | awk '$4 ~ /:80$/ {print $NF}' | grep -o 'users:(("[^"]*"' | head -1 | sed 's/users:(("//;s/"//' || true)"
serve_with=""
case "$listener" in
  "")        serve_with=caddy ;;
  caddy)     serve_with=caddy ;;
  nginx)     serve_with=nginx ;;
  apache2|httpd) serve_with=apache ;;
  *)         echo "Port 80 is already served by '$listener'. Stop it, or serve the page from it by hand: the file is $WEB_DIR/index.html." >&2; exit 1 ;;
esac
if [ "$serve_with" != caddy ] && [ -z "$SNAGS_HOST" ]; then
  echo "$serve_with is already serving on port 80, so the page needs a host name of its own:" >&2
  echo "  SNAGS_HOST=snags.unilife.co.uk bash install.sh" >&2
  exit 1
fi
echo "Port 80: ${listener:-nothing}; serving the page with $serve_with."

# ---- the repo, the page, the timers -----------------------------------------
if [ ! -d "$REPO_DIR/.git" ]; then
  git clone -q "$REPO_URL" "$REPO_DIR"
fi
cd "$REPO_DIR"
git fetch -q origin main && git reset -q --hard origin/main

install -m 755 deploy/hetzner/pull-site.sh /usr/local/bin/castle-way-pull
install -m 755 deploy/hetzner/backup-supabase.sh /usr/local/bin/castle-way-backup

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

# ---- the web server ---------------------------------------------------------
case "$serve_with" in
  caddy)
    if ! command -v caddy >/dev/null; then
      apt-get install -y -q debian-keyring debian-archive-keyring apt-transport-https gnupg
      curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
      curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' > /etc/apt/sources.list.d/caddy-stable.list
      apt-get update -q
      apt-get install -y -q caddy
    fi
    install -m 644 deploy/hetzner/Caddyfile /etc/caddy/Caddyfile
    mkdir -p /etc/systemd/system/caddy.service.d
    printf '[Service]\nEnvironment=SNAGS_HOST=%s\n' "$SNAGS_HOST" > /etc/systemd/system/caddy.service.d/castle-way.conf
    systemctl daemon-reload
    systemctl enable -q caddy
    systemctl restart caddy
    ;;
  nginx)
    cat > /etc/nginx/sites-available/castle-way-snags <<CONF
server {
    listen 80;
    listen [::]:80;
    server_name $SNAGS_HOST;
    root $WEB_DIR;
    index index.html;
    add_header Cache-Control "no-cache";
    location / { try_files \$uri /index.html; }
}
CONF
    ln -sf /etc/nginx/sites-available/castle-way-snags /etc/nginx/sites-enabled/castle-way-snags
    nginx -t
    systemctl reload nginx
    if [ -n "$CERT_EMAIL" ]; then
      command -v certbot >/dev/null || apt-get install -y -q certbot python3-certbot-nginx
      certbot --nginx -d "$SNAGS_HOST" --non-interactive --agree-tos -m "$CERT_EMAIL" --redirect || echo "certbot failed; the page is up on http:// and can be retried: certbot --nginx -d $SNAGS_HOST"
    fi
    ;;
  apache)
    cat > /etc/apache2/sites-available/castle-way-snags.conf <<CONF
<VirtualHost *:80>
    ServerName $SNAGS_HOST
    DocumentRoot $WEB_DIR
    <Directory $WEB_DIR>
        Require all granted
        FallbackResource /index.html
    </Directory>
    Header set Cache-Control "no-cache"
</VirtualHost>
CONF
    a2enmod -q headers >/dev/null || true
    a2ensite -q castle-way-snags >/dev/null
    apache2ctl configtest
    systemctl reload apache2
    if [ -n "$CERT_EMAIL" ]; then
      command -v certbot >/dev/null || apt-get install -y -q certbot python3-certbot-apache
      certbot --apache -d "$SNAGS_HOST" --non-interactive --agree-tos -m "$CERT_EMAIL" --redirect || echo "certbot failed; the page is up on http:// and can be retried: certbot --apache -d $SNAGS_HOST"
    fi
    ;;
esac

/usr/local/bin/castle-way-backup || echo "first backup failed; check network and try: castle-way-backup"

echo
if [ -n "$SNAGS_HOST" ]; then
  scheme=https; [ "$serve_with" != caddy ] && [ -z "$CERT_EMAIL" ] && scheme=http
  echo "Serving $scheme://$SNAGS_HOST/  (Tower 2: $scheme://$SNAGS_HOST/?tower=2)"
  [ "$scheme" = http ] && echo "For HTTPS: CERT_EMAIL=you@unilife.co.uk SNAGS_HOST=$SNAGS_HOST bash install.sh"
else
  echo "Serving http://$(curl -s -4 --max-time 5 ifconfig.me || hostname -I | awk '{print $1}')/  (set SNAGS_HOST and rerun for HTTPS)"
fi
echo "Backups: /var/backups/castle-way-snags/   Pull log: journalctl -u castle-way-pull"
