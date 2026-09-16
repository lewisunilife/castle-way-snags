# Castle Way — snagging list

Public checklist for the Castle Way snagging works, for contractors to tick
off on site. Live at **https://lewisunilife.github.io/castle-way-snags/**
(Tower 1) and **https://lewisunilife.github.io/castle-way-snags/?tower=2**
(Tower 2).

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
and password. The sign-ins are in `AUDIT_USERS` in `site/index.html` (JBA,
JCA, Steve, Bal and Nycole at the time of writing; the username is not
case-sensitive). That is a guard on the view, not a lock on the data: the
page and its source are public, and so is that list.

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

**By studio** is public and lists every studio in the tower in room order,
lowest to highest, with a line for everything still outstanding against each
one — open jobs from the trade lists (audit failures among them, since they
are jobs) and logged issues, each naming its trade. Ticking a failure off in
the trade list clears it from the studio card too.

A failed check whose fix the trade has ticked off counts as done. Once all
nineteen checks have been recorded and nothing is left against the studio —
no open jobs, no open issues — it reads **audited, nothing outstanding** and
moves into the picker's Completed group. It is the tick that clears a
failure, not a second visit from the auditor.

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

The list is the tower being shown. Its rooms come from the control sheet's
room-by-tower table (see **Four towers** below), so nothing outside the sheet
can appear on it.

On Tower 1 the audit log's studio picker offers Stelling's rooms and any
reopened for amendment, since the rest of the tower does not need auditing;
on the other towers it offers every room. Finished ones move into a
**Completed** group rather than leaving the list, so a room can be
re-audited. **Only rooms not audited yet**, above the picker, narrows it to
the rooms with nothing recorded against them, counted in the heading; the
room in hand stays on the list whatever its state, so recording its first
check does not pull it out from under the auditor. Remembered on the device.

One of Stelling's rooms is clear once all nineteen checks have passed, every
logged issue is marked done, **and** nothing is left against it on the trade
lists. A room in the rest of the building is clear once its trade list is
clear.

Logged issues are cleared with **Mark done** in the audit log. That is its
own record rather than an edit, so the page still shows the issue was raised,
by whom, and who cleared it.

Results are append-only: re-auditing a studio adds to the record rather than
overwriting it, and the newest entry for a check is its status. Nothing is
edited or deleted, which is the point of an audit trail.

Stelling's rooms are in `TOWER1_LIST` in `site/index.html`, in the priority
order they gave — nearest move-in first. Everything else comes from the
tower's share of `TOWER_ROOMS`, the same table the MVHR sweep is built from,
so the audit and the MVHR tickets cannot drift apart. Adding a room to the
building means adding it to that table once.

To change Stelling's order, reorder `TOWER1_LIST`; priority is that array's
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
  date given go last rather than first. In date order both views gather what
  they show under a collapsible header per date: By studio groups the rooms,
  and each trade's table groups its rows, so Joinery's 18 Sep jobs open and
  shut as one. Headers carry the count and how many are still outstanding,
  and a header with nothing left showing goes with its rows. **Expand all
  dates** / **Collapse all dates** move the lot; what is left open is
  remembered per trade and date on that device.
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

The button under each filter goes both ways. With everything showing it reads
**Hide every trade** (or source) and unticks the lot, so a single one can be
ticked back on alone; with anything hidden it reads **Show every trade** and
brings them all back.

An audit round is a day on which anything was audited, named by the day —
**15 Sep audit**, **16 Sep audit**. A failed check is filed under the round
of its latest entry, so one that is still failing when it is looked at again
moves into that day's audit on its own, and one nobody has been back to stays
where it was. Hide a day once it has been dealt with and the trade lists show
only what later days found.

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

The date a room is actually let comes from three tabs of the control
spreadsheet, held in `site/index.html` as room number to date and **nothing
else from that sheet** — it holds tenants' names, emails, phone numbers and
travel details, none of which belongs on a public page or in this public
repository. They win in this order:

1. `DEFERRED_TO` — the CW tabs: a tenant who has deferred, and the date they
   now arrive (contract start plus the one or two weeks deferred).
2. `CHECK_IN` — the check-in API: the check-in they have booked. So far this
   holds the seven rooms from the "Tuesday 15th Arrivals" tab.
3. `CONTRACT_START` — the tenants API: the contract start date.

A room with none of the three falls back to the date on Stelling's audit
list; one with nothing at all shows no date rather than a guess. The page
says which kind of date it is — **Deferred to**, **Checks in** / **Checked
in**, **Contract from**, or **Moves in** / **Moved in** for Stelling's own —
in the card, the column and the date headers.

## Ticking, everywhere

Every job can be ticked and unticked from wherever it is shown: its row in
By trade, and its line on the studio card in By studio. It is the same tick
— one key, one record — so a box ticked on a card is struck through on the
trade list with the same name and time against it. Ticked lines stay on the
card struck through until **Hide completed** takes them. Logged issues work
the same way, in the audit log and on the card, and can be reopened; closing
and reopening are each their own entry, so the record shows both.

**Tick all** on a trade ticks every job under it. Unticking all asks first,
because who ticked what, and when, would be lost — and it asks *in the page*,
not with a browser dialog. In-app browsers (Teams, WhatsApp, Outlook link
previews, some Android webviews) swallow `window.confirm()` and answer "no"
without ever showing it, which is why untick-all used to do nothing for some
people. The question now appears under the trade's heading with **Untick
all** and **Keep them**.

## 15M fire regulation rooms

Twenty Tower 1 rooms are 15M fire regulation rooms (CW112, 113, 143, 144,
212, 213, 243, 244, 312, 313, 343, 344, 412, 413, 443, 444, 503, 505, 525
and 526; `FIRE_15M_LIST` in `site/index.html`). Each carries a **15M** mark
beside its move-in on the trade lists and on its By studio card, and the
audit log says so under the studio picker and in its picker labels. A 15M
room with no move-in date reads **15M** in the move-in column, and in date
order those rooms group under "15M fire reg · no move-in date", after every
date and before the rooms with no date at all. The **15M fire reg rooms** control
shows every room, only those rooms, or everything but them, on By trade and
By studio alike; it is remembered on the device and named on the amber
filtered line like the other filters.

## The summary table

**Summary by trade** at the top of the trade view folds away under its
heading: tap the heading to shut or open it. The totals stay on the heading
("236 issues in 89 rooms") so the table can be left shut. Open or shut is
remembered on that device.

## Undo

With **Hide completed** on, a ticked line leaves the page the moment it is
ticked, so a slip has nothing left to untick. A bar at the bottom of the
screen names what was just ticked, one item or a whole trade's Tick all, with
an **Undo** that puts it back unticked. It shows for the last tick only, for
twenty seconds or until the next tick, and only while Hide completed is on:
with it off the line is still there to untick by hand.

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

## Corridors and the stair core

Each tower's audit log also carries one corridor per floor the tower has
rooms on ("Floor 1 corridor" and so on) and a single "Stair core", under
**Corridors and stairs** in the studio picker. They take the checks that
apply to a common area, eleven of the nineteen: fire detection, fire doors,
window restrictors, sockets, leaks, lights, switches, heating, extraction,
windows and blinds, and cleaning; no door fob, bed, taps, toilet or
appliances. A failed check becomes a row under its trade named by the
corridor, and By studio lists them after the rooms under their own heading,
counted apart from the rooms. Their records are keyed `T1-CORRIDOR-1`,
`T1-STAIRS` and so on, so each tower's stay its own.

## Two checks that ask more

**Window restrictors fitted** passes with a count: the Pass button is two,
"Pass · 1 restrictor" and "Pass · 2 restrictors", so the number is recorded
with the pass (`PASS [2]`) and cannot be skipped. A pass from before the
count existed reads as a plain pass. **MVHR door secured** is the nineteenth
check; a fail becomes a ticket under MVHR Cupboards beside the room's sweep
row. Corridors and the stair core do not carry it.

## Habitable or not

Every fail has to say whether the room is still habitable before it is
recorded: the reason box asks **Still habitable?** with two choices, and
Fail is refused until one is picked. The answer rides on the end of the
record as `[h]` or `[nh]`, where a copy of the page from before it existed
still reads the fail and its trade correctly; a fail from before carries
neither and reads as habitable. A room with any current fail marked not
habitable is flagged **Not habitable** on its trade rows and its By studio
card, and the **Habitable** control shows every room, habitable rooms only,
or not habitable rooms only, on By trade and By studio alike, remembered on
the device. Changing the answer on a recorded fail records it again;
passing the check clears it.

## Reopening an audit

Rooms that are not on Stelling's list count as audited already and are kept
off the audit picker. To let an audit that is already done be amended, put
the rooms in `REOPENED` in `site/index.html`: they come back on the picker
under their own heading (at the moment: the 5th floor of Tower 1, "reopened
for amendments"), and on By studio they stay as they are, audited, with
whatever is outstanding against them. Recording a check again supersedes the
last entry, so an amendment is just recording the check as it now stands;
the earlier entry stays in the record. Take the rooms out of `REOPENED` again
to close the reopening.

## Four towers

Castle Way is 257 studios in four towers standing side by side, so a room's
number says which floor it is on and the control sheet's Tower column says
which tower. That column is in `TOWER_ROOMS` in `site/index.html`, written
out floor by floor (16 Sep): on each of floors 1 to 4, rooms 01-13 and 43-48
are Tower 1, 14-19 and 40A-42B Tower 2, 20-39 Tower 3, and on floors 1 and 2
rooms 49-52 are Tower 4, the annexe. The ground floor is CW001 and CW009B in
Tower 1 and the rest in Tower 2. The 5th floor is 01-05 and 25-30 in Tower 1,
06-11 and 22A-24B in Tower 2, 12-21 in Tower 3. That gives Tower 1 89
studios, Tower 2 70, Tower 3 90 and Tower 4 8.

The page shows one tower at a time. `?tower=2` on the address is Tower 2, and
so on up to 4; anything else is Tower 1. The **Tower** buttons under the
heading go between them, and because they are plain links a tower's address
can be sent to a trade and opens on that tower.

Every tower shares the one list, the same database tables and the same audit
sign-in. Each tower's view is its own rooms only: its share of every trade
list (the MVHR sweep covers the whole building, so each tower has its rooms'
share of it; the rest of the trade rows are all Tower 1's), its rooms on By
studio, and its rooms on the audit picker. A row keeps its key whichever
tower shows it, so the split touches nothing that is ticked.

Tower 1 has Stelling's priority list, so its other rooms count as audited
already. The other towers have no list from Stelling, so every room is still
to audit, in room order with the ground floor and the twodios (the A/B rooms)
last, as asked for Tower 2; a check that fails in the audit log becomes a
row under the trade it is sent to, and that is how their snagging lists are
built. To put
a tower's rooms in Stelling's order, give Tower 1's `TOWER1_LIST` a
counterpart for that tower.

Records stay in their tower. An audit entry or a logged issue only shows in
the tower its room belongs to, so nothing from one tower turns up on
another's lists. A comment posted on Tower 2, 3 or 4 is tagged `tower:N`;
one without a tag is Tower 1's, which is every comment made before the
split. Move-in dates are keyed by room, so the three control-sheet maps hold
every tower's rooms.

The annexe is numbered CW601-604 and CW701-704 on the floor plans and
CW149-152 and CW249-252 on the control sheet. The eight MVHR rows for it
were made from the plans, so their keys carry the plan numbers and any tick
on them stays where it is; `ROOM_ALIAS` in the page maps each to the sheet's
number, which is what the page shows and what the audit log records against.

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

Adding a batch of snags: append rows to the trade's array with a source of
their own (`U15 = "Unilife 15th"` is everything logged on the 15 Sep
inspection), so the batch
can be filtered as one. Check each against what the room already carries
first — the same room and action already on the list is the same job, and
adding it again would double it. The summary table's room chips follow the
rows, so a room that joins a trade — by a batch or by an audit failure —
shows there without a rebuild.

Two rows with the same room and the same action wording are treated as one
job. That is what lets the same item be listed under more than one heading
without being counted or ticked twice.

## Starting a fresh round of works

```sql
truncate table public.castle_way_snags;
truncate table public.castle_way_comments;
```
