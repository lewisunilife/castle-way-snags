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

A check tapped Fail but not yet recorded exists only in the panel — nothing
about it is saved. The panel is redrawn whenever anyone's entry arrives, so
the open box, the half-typed reason, the chosen trade and the cursor are held
and put back, and the panel is left alone entirely when the record behind it
has not changed. The same draft is kept on the device too, so a refresh
mid-sentence — including the one a new build asks for — hands it back.

## Deploying while people are on it

Pushing a build changes the page, not the data. Ticks, notes and audit records
live in Supabase and are append-only or key-addressed; an open page keeps
running the old build until it is refreshed, and the offline queue survives
the refresh under the same storage key. What *would* lose data is changing a
job's key — its room and action wording — because ticks and notes hang off
that key. Before pushing, compare the set of job keys the deployed build
produces with the new one; today's build was checked at 383 keys, identical.

Every check has a trade it lands on by default, but the auditor decides. The
reason box carries a **Send to** dropdown with all thirteen trades and
**Unassigned**, so a fail can go where the work actually belongs rather than
where the checklist guessed. Changing it on an already-failed check moves the
line there and then, reason and all.

A failed check becomes a row on that trade's list like any other job —
tickable, noteable, counted, and caught by **Tick all** and **Hide
completed** — carrying the room, its move-in date, the check and the reason,
marked **Audit** in the Source column with a red edge. Its identity is the
room and the action, the same as every other job, so a tick stays with it.

Passing the check later takes the row away again; re-assigning it moves the
row to the new trade with its reason. A fail left **Unassigned** gets its own
section at the foot of the trade view, so it is waiting to be given to someone
rather than lost.

The trade headings, the section counts, the summary table and the total are
all worked out from the rows, so a failure joining a trade cannot leave them
behind: the total goes from "0 of 383" to "0 of 384" and back when the check
passes.

**By studio** is public and lists all 257 studios in the tower in room order,
lowest to highest, with a line for everything still outstanding against each
one — open jobs from the trade lists (audit failures among them, since they
are jobs) and logged issues, each naming its trade. Ticking a failure off in
the trade list clears it from the studio card too.

A studio whose failures have been put right but not yet re-audited reads
**put right, waiting on a re-audit** rather than clear: a failed check stays
failed until it is audited again, which is the point of auditing it.

The 37 rooms on Stelling's list read **waiting to be audited** until their
audit is started. The rest of the building has been audited already, so what
shows against those rooms is simply what is left on the trade lists; a room
with nothing left reads **no tickets outstanding**.

Each card leads with the move-in date where there is one, then the floor, room
type and Stelling priority. **Order by** switches between room number and
move-in date, soonest arrival first; rooms with no date given go to the end
rather than the front.

In move-in date order the rooms are gathered under a collapsible header per
date, showing that day's room count and how many still have something against
them, so a day's arrivals open and shut as one. Dated headers start open and
the undated pile starts shut, since it is every room with no arrival booked;
**Expand all dates** and **Collapse all dates** move the lot, and whatever is
left open is remembered on that device.

A count above the list gives the split — waiting, outstanding, clear. Three
filters narrow it:

- **Hide rooms with nothing outstanding** drops the clear ones.
- **Hide ground floor** drops CW0xx.
- **Filter tasks by trade** hides a trade's jobs from every card, so the view
  can be read without, say, the building-wide MVHR sweep on top of it.

The counts follow the filters, and an amber line above the list says which are
on, because a room can read clear only because what is left in it is hidden.
The audit log's own idea of whether a studio is finished ignores the filters
entirely — that is a fact about the studio, not about what someone chose to
look at. All four choices are remembered on that device and change nobody
else's view.

The list is Castle Way Tower 1 only. It is generated from the floor layouts —
ground floor, five standard floors, the short fifth, and the two annexe
landings — which is where the 257 comes from; nothing outside those layouts
can appear on it.

The audit log's studio picker offers only Stelling's 37, since the rest of the
building does not need auditing. Finished ones move into a **Completed** group
rather than leaving the list, so a room can be re-audited.

One of Stelling's rooms is clear once all eighteen checks have passed, every
logged issue is marked done, **and** nothing is left against it on the trade
lists. A room in the rest of the building is clear once its trade list is
clear.

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

## The list controls

One panel under the view switcher drives **By trade** and **By studio** alike,
so a filter set in one holds in the other. All four choices are remembered on
that device and are per person — they change nobody else's view.

- **Order by** — room number, or move-in date soonest first. It orders the
  rows inside every trade as well as the studio cards. Rooms with no move-in
  date given go last rather than first. In By studio, date order also gathers
  the rooms under a collapsible header per date.
- **Hide completed** — drops ticked lines from the trade tables, and rooms
  with nothing outstanding from By studio. A trade with nothing left showing
  disappears whole rather than leaving a heading over an empty table.
- **Hide ground floor** — drops CW0xx from both.
- **Filter by trade** — hides a trade's section in By trade and its tasks in
  By studio, so the view can be read without, say, the building-wide MVHR
  sweep on top of it.
- **Filter by source** — the same, by where a job came from: CW Issues Log,
  Stelling, JBA, Arrivals list, Unilife, and one entry per audit round. The
  list is read off the rows, so a new round appears in it by itself.

An audit round is a day on which anything was audited: the first such day is
**Audit 1**, the next **Audit 2**, and so on. A failed check is filed under
the round of its latest entry, so one that is still failing when it is looked
at again moves from Audit 1 into Audit 2 on its own, and one nobody has been
back to stays where it was. Hide Audit 1 once it has been dealt with and the
trade lists show only what the later rounds found.

An amber line says which filters are on, because a room can read clear only
because what is left in it is hidden. What the counts do about it differs by
view and the line says which: in By trade the progress count and the summary
still count everything, so "18 of 27 ticked" stays true whatever is on screen;
in By studio the counts follow the filter, since whether a room has anything
outstanding is the question being asked. The audit log's own idea of whether a
studio is finished ignores the filters entirely.

Each trade table carries a **Move-in** column. Only the rooms on Stelling's
list have a date so far, so the rest are blank rather than guessed; on a phone
the line is dropped entirely rather than leaving a gap on every card.

`MOVE_IN_DATES` in `site/index.html` carries the dates from the control
sheet — room number to date, one line each, and **nothing else from that
sheet**: it holds tenants' names, emails, phone numbers and travel details,
none of which belongs on a public page or in this public repository. So far
it holds the seven rooms from the "Tuesday 15th Arrivals" tab (11–15 Sep
2026); the master tab would cover the rest. Anything in it fills a room with
no date of its own; a date already against a Stelling room wins. A date that
has passed reads **Moved in** rather than **Moves in**.

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
