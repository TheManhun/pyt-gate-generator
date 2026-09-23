-- PYT Gate Generator stats -- live schema for the aijqcrrcreectihaeqoc
-- Supabase project, for reference/rebuild.
--
-- pyt_generator_visits, its RLS/insert policy, and the first
-- get_pyt_stats() (pageviews/unique_visitors/today/last_hour) shipped
-- first (replacing an earlier get_visit_count() draft that was never
-- deployed). pyt_generator_generations and pyt_generator_mods were
-- added later (see each one's own comment below for why) -- this file
-- reflects the CURRENT live design as of the mods-registry pass,
-- reconstructed by querying the live REST endpoint directly (this repo
-- and the Supabase project aren't edited from the same session, so
-- this file can drift -- if it looks stale next to what get_pyt_stats()
-- actually returns, trust the live endpoint over this file).
--
-- No public SELECT policy exists on pyt_generator_visits/generations --
-- referrer/session_id stay private. get_pyt_stats()/get_pyt_mods() are
-- SECURITY DEFINER functions that return only what the page needs, so
-- they're safe to grant to anon; pyt_generator_mods itself also grants
-- anon SELECT directly, since a mod's name/url/note/author is meant to
-- be public either way.

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
-- mod using the format." pyt_generator_generations: one row per real
-- "Copy code" or "Download" click (the page's own generate() runs on
-- every keystroke to update the live preview, which would be noise --
-- only a real Copy/Download is a modder actually taking a finished
-- script away, so that's the one event worth counting). This pass also
-- first tracked "live mods using the format" as a plain hand-bumped
-- number in a pyt_generator_config table -- superseded by the fourth
-- pass below, which replaced it with a real registry instead.
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

-- Fourth pass -- Blender Claude applied the third pass above, then
-- replaced its own `pyt_generator_config` manual-bump number with a
-- REAL mods registry instead: `live_mods_using_format` is now COUNTED
-- from actual rows here, not hand-incremented. (`pyt_generator_config`
-- may still exist live -- not dropped by this file, its status just
-- isn't tracked here any more since nothing reads it now.)
--
-- One row per published mod using the format. No anon insert/update
-- policy: added by hand (Epod, or whoever has the Supabase dashboard)
-- once a modder's mod actually ships -- same "not something the page
-- itself should write" reasoning as the visit/generation tables' own
-- missing SELECT policy, just inverted (public read, private write).
create table if not exists public.pyt_generator_mods (
  id bigint generated always as identity primary key,
  added_at timestamptz not null default now(),
  name text not null,
  url text not null,
  author text,
  note text
);

alter table public.pyt_generator_mods enable row level security;

create policy "Allow anonymous mod reads"
on public.pyt_generator_mods
for select
to anon
using (true);

-- Seed row -- the first (and, as of this file, only) live mod. Skipped
-- on a rebuild if a row with this URL already exists.
insert into public.pyt_generator_mods (name, url, author, note)
select
  'Pay Your Tolls Sign Set',
  'https://steamcommunity.com/sharedfiles/filedetails/?id=3806007712',
  'Epod',
  'Four era-styled toll signs (1850s/1920s/1980s/1990s) that turn any decorative toll plaza into a working tollway.'
where not exists (
  select 1 from public.pyt_generator_mods
  where url = 'https://steamcommunity.com/sharedfiles/filedetails/?id=3806007712'
);

-- Returns the mods list as a JSON array -- same shape get_pyt_stats()
-- embeds under its own "mods" key, callable directly if a future page
-- ever wants just this without the rest of the stats.
create or replace function public.get_pyt_mods()
returns jsonb
language sql
security definer
set search_path = public
as $$
  select coalesce(jsonb_agg(jsonb_build_object(
    'name', name, 'url', url, 'author', author, 'note', note
  ) order by added_at), '[]'::jsonb)
  from public.pyt_generator_mods;
$$;

grant execute on function public.get_pyt_mods() to anon;

-- Returns { pageviews, unique_visitors, today, last_hour,
-- scripts_generated, live_mods_using_format, mods } as JSON. The
-- generator page's own counter chart shows unique_visitors,
-- scripts_generated and live_mods_using_format together, then lists
-- `mods` as social proof next to the "get featured" pitch; the rest is
-- there for querying from the Supabase SQL editor.
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
    'live_mods_using_format', (select count(*) from public.pyt_generator_mods),
    'mods', (select public.get_pyt_mods())
  );
$$;

grant execute on function public.get_pyt_stats() to anon;

-- Your own queries (Supabase SQL editor, not exposed to the page):
--   select referrer, count(*) from pyt_generator_visits
--     group by referrer order by count(*) desc;   -- where traffic comes from
--   insert into public.pyt_generator_mods (name, url, author, note)
--     values ('Mod Name', 'https://steamcommunity.com/...', 'Author', 'One-line description');
--                                                  -- add a newly-published mod to the featured list
