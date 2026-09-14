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

## The audit log

Three views, one URL: **By trade** (the snagging list), **By studio**, and
**Audit log**. The first two are public; the audit log asks for a username
and password.

**That sign-in guards the view, not the data.** This is a public page and its
source carries the credentials, so anyone who opens developer tools or reads
this repository can see them and get in, and the audit records are reachable
through the same key the public page already uses. It keeps the audit out of
the way of people who have no business in it. It is not a lock. Treat the
audit log as readable by anyone who goes looking.

Eighteen checks per studio in priority order — life safety, then what makes a
studio habitable, then what makes it work, then handover. Pass is one tap;
Fail asks why before it records anything, and the reason travels with it.

Every check has a trade it lands on by default, but the auditor decides. The
reason box carries a **Send to** dropdown with all thirteen trades and
**Unassigned**, so a fail can go where the work actually belongs rather than
where the checklist guessed. Changing it on an already-failed check moves the
line there and then, reason and all.

A failed check appears on that trade's list under "From the audit", carrying
the studio, the check and the reason. Passing the check later takes the line
away again. A fail left **Unassigned** shows in its own section at the foot of
the trade view, so it is waiting to be given to someone rather than lost.

**By studio** is public and lists all 257 studios in the tower, not only the
ones with something against them, so an un-started studio is visible as an
un-started studio. Each card gives the floor, how many of the checks are done
and a line per outstanding thing; Stelling's rooms also carry their priority,
room type and move-in date.

The 37 rooms Stelling are auditing come first, in their priority order, and
the rest of the building follows under its own heading so they are not buried
under two hundred rooms nobody has been asked to audit. The studio picker in
the audit log is grouped the same way.

A studio moves down into **Completed** once all eighteen checks have passed
and every logged issue is marked done. Completed studios stay on the page
rather than disappearing, and drop out of the working list in the audit's
studio picker into a **Completed** group, so what is left to audit is what
the picker shows.

Logged issues are cleared with **Mark done** in the audit log. That is its
own record rather than an edit, so the page still shows the issue was raised,
by whom, and who cleared it.

Results are append-only: re-auditing a studio adds to the record rather than
overwriting it, and the newest entry for a check is its status. Nothing is
edited or deleted, which is the point of an audit trail.

Stelling's 37 rooms are in `STELLING_LIST` in `site/index.html`, in the
priority order they gave — nearest move-in first. Everything else comes from
`EVERY_ROOM`, the same building-wide list the MVHR sweep is built from, so
the audit and the MVHR tickets cannot drift apart: both cover the same 257
rooms. Adding a room to the building means editing the floor layouts once.

To change Stelling's order, reorder `STELLING_LIST`; priority is that array's
order, not a stored number, so it cannot fall out of step.

## Who is carrying each trade

Set in the `ASSIGNED` map in `site/index.html`, keyed on the section key. It
shows against the section heading and in the summary; a trade with nobody
against it shows a dash rather than a blank, so an unassigned one is visible
rather than just quiet.

## Hiding what is done

**Hide completed** at the top drops every ticked line out of the list, and a
trade with nothing left in it disappears whole rather than leaving a heading
over an empty table. The counts still count everything, so "18 of 27 ticked"
stays true whatever is on screen. The choice is remembered on that device and
is per person — it changes nobody else's view.

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
