# Serving the list from a Hetzner box

The page is one static file and holds no data: every tick, note and audit
entry lives in Supabase. So a second host is nothing more than a second
place the same file is served from, and both show the same live data. The
GitHub Pages link keeps working untouched throughout.

## One-time setup

On a Debian or Ubuntu server, as root:

```bash
git clone https://github.com/lewisunilife/castle-way-snags.git /opt/castle-way-snags
SNAGS_HOST=snags.unilife.co.uk bash /opt/castle-way-snags/deploy/hetzner/install.sh
```

Point the DNS A record for that host at the server first and Caddy fetches
the HTTPS certificate itself. Without `SNAGS_HOST` it serves plain HTTP on
the server's address, which is fine for a look before the DNS is in; run the
script again with the host set once it is.

What is put in place:

| Path or unit | What it is |
|---|---|
| `/opt/castle-way-snags` | a clone of the repo, pulled from `main` every minute |
| `/var/www/castle-way-snags/index.html` | the page Caddy serves, swapped in one move |
| `/var/backups/castle-way-snags/<time>/` | nightly JSON copies of the two tables, kept 90 days |
| `castle-way-pull.timer` | the minute-by-minute pull |
| `castle-way-backup.timer` | the 02:30 backup |

## Updates

Nothing to do: a push to `main` reaches the box within a minute, after the
GitHub workflow has checked that no job key would be lost. Both hosts serve
the same commit.

## The backup

`backup-supabase.sh` reads the two tables through the same publishable key
the page uses (read access is what the page has), in pages of 1000 rows, and
writes them as JSON. No secret is stored on the box. To take one by hand:

```bash
castle-way-backup
ls /var/backups/castle-way-snags/
```

To put a copy back after a mistake, the rows can be re-sent with the same
key: the page's access rules allow inserting comments and upserting snag
rows, and nothing can delete. Ask before doing that; it should be rare.

## If the box is ever the only host

It is not, by design. If GitHub Pages goes away, this host carries on
serving the last pulled page; if this box goes away, GitHub Pages does. The
data is in neither place.
