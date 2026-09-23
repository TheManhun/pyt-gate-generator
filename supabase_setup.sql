-- PYT Gate Generator visit counter -- live schema for the
-- aijqcrrcreectihaeqoc Supabase project, for reference/rebuild.
-- Table, RLS and the insert policy already existed before this file's
-- second pass; get_pyt_stats() below is the one piece that was added
-- after (replacing an earlier get_visit_count() draft that was never
-- deployed -- the page now calls get_pyt_stats() to match).
--
-- No public SELECT policy exists on the table and none should be
-- added -- referrer/session_id stay private. get_pyt_stats() is a
-- SECURITY DEFINER function that returns only aggregate counts, never
-- the rows, so it's safe to grant to anon.

create table if not exists public.pyt_generator_visits (
  id bigint generated always as identity primary key,
  created_at timestamptz not null default now(),
  referrer text,
  page text,
  session_id text
);

alter table public.pyt_generator_visits enable row level security;

-- Postgres has no CREATE POLICY IF NOT EXISTS; this already exists live,
-- so on a rebuild just run the plain form below (errors harmlessly if
-- it's still there):
create policy "Allow anonymous visit inserts"
on public.pyt_generator_visits
for insert
to anon
with check (true);

-- Third pass -- Epod: "add a counter to how many scripts have been
-- generated... 17 modders visited * 8 gate scripts generated * 1 live
-- mod using the format." Two new pieces, same shape as the visit
-- counter above:
--   1. pyt_generator_generations -- one row per real "Copy code" or
--      "Download" click (the page's own generate() runs on every
--      keystroke to update the live preview, which would be noise --
--      only a real Copy/Download is a modder actually taking a
--      finished script away, so that's the one event worth counting).
--   2. pyt_generator_config -- a plain key/value table for the ONE
--      number that can't be counted automatically at all: how many
--      real, published mods use the format. That's tracked by hand
--      (Epod hears about a new one via Discord/Workshop comment), so
--      it lives as a row you UPDATE directly in the Supabase SQL
--      editor -- no code redeploy needed to bump it.
create table if not exists public.pyt_generator_generations (
  id bigint generated always as identity primary key,
  created_at timestamptz not null default now(),
  session_id text
);

alter table public.pyt_generator_generations enable row level security;

create policy "Allow anonymous generation inserts"
on public.pyt_generator_generations
for insert
to anon
with check (true);

create table if not exists public.pyt_generator_config (
  key text primary key,
  value integer not null
);

alter table public.pyt_generator_config enable row level security;

-- No insert/update policy for anon here on purpose -- this table is
-- edited by hand from the Supabase SQL editor (or Table editor) only,
-- never from the page itself. Read access is still only ever through
-- get_pyt_stats() below, same as everything else.
insert into public.pyt_generator_config (key, value)
values ('live_mods_using_format', 1)
on conflict (key) do nothing;

-- To bump the manually-tracked count once a new mod goes live:
--   update public.pyt_generator_config
--   set value = value + 1
--   where key = 'live_mods_using_format';

-- Returns { pageviews, unique_visitors, today, last_hour,
-- scripts_generated, live_mods_using_format } as JSON. The generator
-- page's own counter chart shows unique_visitors, scripts_generated
-- and live_mods_using_format together; the rest is there for querying
-- from the Supabase SQL editor.
create or replace function public.get_pyt_stats()
returns jsonb
language sql
security definer
set search_path = public
as $$
  select jsonb_build_object(
    'pageviews', (select count(*) from public.pyt_generator_visits),
    'unique_visitors', (select count(distinct session_id) from public.pyt_generator_visits),
    'today', (select count(*) from public.pyt_generator_visits where created_at >= date_trunc('day', now())),
    'last_hour', (select count(*) from public.pyt_generator_visits where created_at >= now() - interval '1 hour'),
    'scripts_generated', (select count(*) from public.pyt_generator_generations),
    'live_mods_using_format', (select value from public.pyt_generator_config where key = 'live_mods_using_format')
  );
$$;

grant execute on function public.get_pyt_stats() to anon;

-- Your own queries (Supabase SQL editor, not exposed to the page):
--   select referrer, count(*) from pyt_generator_visits
--     group by referrer order by count(*) desc;   -- where traffic comes from
--   update public.pyt_generator_config set value = value + 1
--     where key = 'live_mods_using_format';        -- bump the manual mod count
