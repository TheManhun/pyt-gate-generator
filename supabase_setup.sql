-- PYT Gate Generator visit counter -- run this once in the Supabase
-- SQL editor for the aijqcrrcreectihaeqoc project.
--
-- Table takes anonymous inserts only (no public SELECT -- referrer/
-- session_id stay private). The public counter on the page comes from
-- get_visit_count() instead, a SECURITY DEFINER function that returns
-- only a number, never the rows.

create table if not exists public.pyt_generator_visits (
  id bigint generated always as identity primary key,
  created_at timestamptz not null default now(),
  referrer text,
  page text,
  session_id text
);

alter table public.pyt_generator_visits enable row level security;

create policy "Allow anonymous visit inserts"
on public.pyt_generator_visits
for insert
to anon
with check (true);

-- Distinct session_id, not raw row count, so a reload doesn't inflate
-- the number the page shows.
create or replace function public.get_visit_count()
returns bigint
language sql
security definer
set search_path = public
as $$
  select count(distinct session_id) from public.pyt_generator_visits;
$$;

grant execute on function public.get_visit_count() to anon;

-- Your own queries (Supabase SQL editor, not exposed to the page):
--   select count(*) from pyt_generator_visits;                    -- total page loads
--   select count(distinct session_id) from pyt_generator_visits;  -- unique visitors
--   select referrer, count(*) from pyt_generator_visits
--     group by referrer order by count(*) desc;                   -- where traffic comes from
