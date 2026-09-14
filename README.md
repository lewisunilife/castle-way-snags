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

## Updating the list

Edit the `sections` array in `site/index.html` and push. Row keys are
`<section>-<position>` (e.g. `joinery-7`), so adding to the end of a section is
safe, but **inserting or reordering rows re-points existing ticks**. If you
reorder, clear the table first:

```sql
truncate table public.castle_way_snags;
```

## Starting a fresh round of works

```sql
truncate table public.castle_way_snags;
truncate table public.castle_way_comments;
```
