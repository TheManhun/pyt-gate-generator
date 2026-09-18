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

-- Returns { pageviews, unique_visitors, today, last_hour } as JSON.
-- The generator page shows unique_visitors in its footer counter; the
-- rest is there for querying from the Supabase SQL editor.
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
    'last_hour', (select count(*) from public.pyt_generator_visits where created_at >= now() - interval '1 hour')
  );
$$;

grant execute on function public.get_pyt_stats() to anon;

-- Your own queries (Supabase SQL editor, not exposed to the page):
--   select referrer, count(*) from pyt_generator_visits
--     group by referrer order by count(*) desc;   -- where traffic comes from
