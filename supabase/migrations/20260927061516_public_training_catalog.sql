-- Versioned public reference data. Student/workout tables are unchanged.
create table public.catalog_releases (
  version text primary key,
  active boolean not null default false,
  exercise_count integer not null check (exercise_count > 0),
  method_count integer not null check (method_count > 0),
  created_at timestamptz not null default now()
);
create unique index catalog_single_active_release on public.catalog_releases (active) where active;

create table public.catalog_exercises (
  release_version text not null references public.catalog_releases(version),
  id text not null,
  sort_order integer not null check (sort_order >= 0),
  summary jsonb not null check (jsonb_typeof(summary) = 'object' and summary->>'id' = id and not summary ? 'instructions'),
  instructions jsonb not null default '[]'::jsonb check (jsonb_typeof(instructions) = 'array'),
  primary key (release_version, id),
  unique (release_version, sort_order)
);

create table public.catalog_training_methods (
  release_version text not null references public.catalog_releases(version),
  id text not null,
  sort_order integer not null check (sort_order >= 0),
  content jsonb not null check (jsonb_typeof(content) = 'object' and content->>'id' = id),
  primary key (release_version, id),
  unique (release_version, sort_order)
);

alter table public.catalog_releases enable row level security;
alter table public.catalog_exercises enable row level security;
alter table public.catalog_training_methods enable row level security;

revoke all on public.catalog_releases, public.catalog_exercises, public.catalog_training_methods from anon, authenticated;
grant select on public.catalog_releases, public.catalog_exercises, public.catalog_training_methods to anon, authenticated;
grant all on public.catalog_releases, public.catalog_exercises, public.catalog_training_methods to service_role;

create policy "Public catalog releases are readable" on public.catalog_releases for select to anon, authenticated using (true);
create policy "Public exercises are readable" on public.catalog_exercises for select to anon, authenticated using (true);
create policy "Public training methods are readable" on public.catalog_training_methods for select to anon, authenticated using (true);

comment on table public.catalog_exercises is 'Public PT-BR exercise reference data; full instructions are selected on demand. Source licenses in tool/exercise_catalog.';
