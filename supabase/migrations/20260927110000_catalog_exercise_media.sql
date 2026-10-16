-- Licensed exercise demonstrations. Metadata is public; media files remain at
-- the pinned upstream revision and are fetched only when viewed.
create table public.catalog_exercise_media (
  id text primary key,
  name text not null,
  search_name text not null,
  equipment text not null,
  catalog_exercise_id text,
  thumbnail_url text not null,
  animation_url text not null,
  attribution text not null,
  source_revision text not null
);

create index catalog_exercise_media_catalog_id_idx
  on public.catalog_exercise_media (catalog_exercise_id)
  where catalog_exercise_id is not null;
create index catalog_exercise_media_search_idx
  on public.catalog_exercise_media (search_name text_pattern_ops);

alter table public.catalog_exercise_media enable row level security;
revoke all on public.catalog_exercise_media from anon, authenticated;
grant select on public.catalog_exercise_media to anon, authenticated;
grant all on public.catalog_exercise_media to service_role;
create policy "Exercise media is readable" on public.catalog_exercise_media
  for select to anon, authenticated using (true);
