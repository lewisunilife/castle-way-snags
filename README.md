# Castle Way Tower 1 — snagging list

Public checklist for the Castle Way Tower 1 snagging works, for contractors to
tick off on site. Live at **https://lewisunilife.github.io/castle-way-snags/**

- `site/index.html` — the whole page, one file
- `supabase-setup.sql` — database setup for shared ticks
- `.github/workflows/pages.yml` — publishes `site/` on every push to `main`

## Connecting the shared state

Until this is done, ticks and notes save to whichever device made them — the
page says so at the top. Once connected, one contractor's tick appears on
everyone else's screen within a second.

1. Create a **new, empty** Supabase project at
   <https://supabase.com/dashboard>. Not an existing one — see the warning
   below.
2. **SQL Editor → New query** → paste all of `supabase-setup.sql` → **Run**.
3. **Project Settings → API** → copy the **Project URL** and the **anon
   public** key.
4. Edit `site/index.html` and fill in the two lines near the top of the
   `<script>`:

   ```js
   var SUPABASE_URL = "PASTE_YOUR_SUPABASE_URL_HERE";
   var SUPABASE_ANON_KEY = "PASTE_YOUR_SUPABASE_ANON_KEY_HERE";
   ```

5. Commit. The workflow redeploys in about a minute.

Then open the page on two devices — the bar at the top should read
**"Live — everyone sees this list update"** in green.

> **Never put the `service_role` key in this file.** This repository is
> public, so anything in it is readable by anyone. The `anon` key is designed
> for that; `service_role` bypasses every access rule.
>
> Use a dedicated Supabase project for the same reason: the anon key published
> here can call that project's API, so it should have nothing in it but this
> snagging list.

## Who can edit the list

Anyone with the URL. That is the trade-off for having no logins, the same as a
Google Sheet shared with link editing. Each tick and note is stamped with
whatever name the person typed in the box at the top, so there is a trail,
but nothing verifies it.

## How it protects the ticks

- **Nothing is lost when the signal drops.** A tick or note is written to the
  phone first, shown straight away, and retried until the server confirms it.
  The row shows an amber edge and "saving..." until it lands, and the bar at
  the top counts anything still outstanding. Closing the page mid-tick is
  safe; it sends on the next visit. Trying to leave with work outstanding
  prompts first.
- **Your own change is never overwritten by an older copy** arriving from the
  server, and a reply that turns up out of order is discarded in favour of
  whichever copy is newer.
- **Retried comments do not double-post** — each carries an id generated on
  the device, so a retry after a reply that never arrived is recognised.
- **Work ticked before the list was connected is carried up once**, not
  discarded.
- **Ticks cannot be deleted** by anyone using the page — the access rules
  allow read, insert and update only.

## Updating the list

Edit the `sections` array in `site/index.html` and push. That is the only
edit: the summary table, each trade's issue and room counts, and the totals
are all worked out from the rows, so they cannot drift out of step.

Row keys are derived from the room and the action, so **reordering rows,
moving one between trades or inserting new ones is safe** — existing ticks
and notes stay with their job.

Rewording an action changes its key, which orphans that job's ticks and notes.
That is deliberate: the job has changed, so it is no longer the thing that was
ticked. If you reword something and want to keep the history, re-tick it.

Two rows with the same room and the same action wording are treated as one
job. That is what lets the same item be listed under more than one heading
without being counted or ticked twice.

## Starting a fresh round of works

```sql
truncate table public.castle_way_snags;
truncate table public.castle_way_comments;
```
