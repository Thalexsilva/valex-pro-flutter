-- Link previously unmatched GIFs to newly imported catalog exercises.
update public.catalog_exercise_media set catalog_exercise_id='gymvisual-' || id
where source_revision='7455efae41b330c265e7cd4b78dfa848e7ce5ebd' and catalog_exercise_id is null;
do $verify$ begin
  if (select count(*) from public.catalog_exercise_media where source_revision='7455efae41b330c265e7cd4b78dfa848e7ce5ebd'
      and catalog_exercise_id is not null) <> 1324 then
    raise exception 'Incomplete media links';
  end if;
end $verify$;
