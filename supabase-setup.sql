-- Castle Way Tower 1 snagging list — shared state for the public page in
-- public/castle-way-snags/.
--
-- IMPORTANT: run this in a Supabase project that holds NOTHING ELSE.
-- The page is public, so its anon key is public too. Anyone who reads the
-- page source can call this project's API with that key. A dedicated
-- project keeps that blast radius to this snagging list and nowhere near
-- the pricing snapshots or api_keys tables.

-- ---------------------------------------------------------------------
-- Tables
-- ---------------------------------------------------------------------

-- One row per line of the snagging list. The id is the line's stable key
-- from the page (e.g. 'joinery-7'), so the page can upsert without
-- needing to read first.
create table if not exists public.castle_way_snags (
  id          text primary key,
  done        boolean     not null default false,
  note        text        not null default '',
  updated_by  text        not null default '',
  updated_at  timestamptz not null default now()
);

create table if not exists public.castle_way_comments (
  id         uuid        primary key default gen_random_uuid(),
  body       text        not null,
  author     text        not null default '',
  created_at timestamptz not null default now()
);

create index if not exists castle_way_comments_created_at_idx
  on public.castle_way_comments (created_at);

-- ---------------------------------------------------------------------
-- Row level security
--
-- Contractors are anonymous — there are no logins — so the anon role gets
-- exactly the rights the page needs and nothing more:
--   snags     read, create, amend     (no delete: a line cannot vanish)
--   comments  read, create            (no amend, no delete: an audit trail)
-- ---------------------------------------------------------------------

alter table public.castle_way_snags    enable row level security;
alter table public.castle_way_comments enable row level security;

drop policy if exists snags_read   on public.castle_way_snags;
drop policy if exists snags_create on public.castle_way_snags;
drop policy if exists snags_amend  on public.castle_way_snags;

create policy snags_read   on public.castle_way_snags for select using (true);
create policy snags_create on public.castle_way_snags for insert with check (true);
create policy snags_amend  on public.castle_way_snags for update using (true) with check (true);

drop policy if exists comments_read   on public.castle_way_comments;
drop policy if exists comments_create on public.castle_way_comments;

create policy comments_read   on public.castle_way_comments for select using (true);
create policy comments_create on public.castle_way_comments for insert with check (true);

-- Keep a comment's stamp honest: ignore whatever the client sends for
-- created_at and set it server-side.
create or replace function public.castle_way_comment_stamp()
returns trigger
language plpgsql
as $$
begin
  new.created_at := now();
  return new;
end;
$$;

drop trigger if exists castle_way_comment_stamp on public.castle_way_comments;
create trigger castle_way_comment_stamp
  before insert on public.castle_way_comments
  for each row execute function public.castle_way_comment_stamp();

-- Same for snags: phones' clocks disagree, so the server decides when a
-- line was last touched. The page shows its own time immediately and is
-- corrected by the realtime echo a moment later.
create or replace function public.castle_way_snag_stamp()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists castle_way_snag_stamp on public.castle_way_snags;
create trigger castle_way_snag_stamp
  before insert or update on public.castle_way_snags
  for each row execute function public.castle_way_snag_stamp();

-- ---------------------------------------------------------------------
-- Realtime — this is what makes one contractor's tick appear on
-- everyone else's phone.
-- ---------------------------------------------------------------------

do $$
begin
  begin
    alter publication supabase_realtime add table public.castle_way_snags;
  exception when duplicate_object then
    null;
  end;

  begin
    alter publication supabase_realtime add table public.castle_way_comments;
  exception when duplicate_object then
    null;
  end;
end;
$$;
