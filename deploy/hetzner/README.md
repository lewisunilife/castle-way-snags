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

Point the DNS A record for that host at the server first. The script looks
at what already answers on port 80 before it touches anything:

- **Nothing** (a fresh box): Caddy serves the page and fetches the HTTPS
  certificate itself. Without `SNAGS_HOST` it serves plain HTTP on the
  server's address, fine for a look before the DNS is in; run it again with
  the host set once it is.
- **nginx or apache already there** (say, a WordPress site): the page gets a
  server block of its own for `SNAGS_HOST`, beside what is already served,
  which is left alone. A host name is required in that case. Add
  `CERT_EMAIL=you@unilife.co.uk` and certbot puts HTTPS on it; without it the
  page is up on plain HTTP and the script prints the command for later.
- **Anything else on port 80**: it stops and says what it found.

The script is safe to run again; it only rewrites what it put there.

What is put in place:

| Path or unit | What it is |
|---|---|
| `/opt/castle-way-snags` | a clone of the repo, pulled from `main` every minute |
| `/var/www/castle-way-snags/index.html` | the page that is served, swapped in one move |
| `/var/backups/castle-way-snags/<time>/` | nightly JSON copies of the two tables, kept 90 days |
| `castle-way-pull.timer` | the minute-by-minute pull |
| `castle-way-backup.timer` | the 02:30 backup |

## Running it from GitHub instead

`.github/workflows/hetzner.yml` does the same over SSH from a GitHub Actions
runner, so nobody has to open a console on the box. It needs two repository
secrets (Settings > Secrets and variables > Actions): `HETZNER_HOST`, the
server's address, and `HETZNER_SSH_KEY`, a private key whose public half is
in the server's `/root/.ssh/authorized_keys` (`HETZNER_USER` if not root).
Then Actions > Deploy to Hetzner > Run workflow, with the host name and the
certificate email as inputs. It never runs on a push, only when started, and
it ends by printing what is now on the box: the timers, the backups and what
holds ports 80 and 443.

To make a key on the server itself, in its console:

```bash
ssh-keygen -t ed25519 -N "" -f /root/.ssh/castle-way-deploy
cat /root/.ssh/castle-way-deploy.pub >> /root/.ssh/authorized_keys
cat /root/.ssh/castle-way-deploy      # this is HETZNER_SSH_KEY
rm /root/.ssh/castle-way-deploy
```

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
