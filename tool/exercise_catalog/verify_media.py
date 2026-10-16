"""Read-only check of the public exercise-media table."""
import json
from pathlib import Path
from urllib.parse import urlencode
from urllib.request import Request, urlopen

HERE = Path(__file__).resolve().parent
config = json.loads((HERE.parent.parent / 'config/beta.json').read_text(encoding='utf-8-sig'))
manifest = json.loads((HERE.parent.parent / '.dart_tool/catalog-media/7455efae41b3/manifest.json').read_text(encoding='utf-8'))


def get(params):
    url = config['SUPABASE_URL'] + '/rest/v1/catalog_exercise_media?' + urlencode(params)
    request = Request(url, headers={'apikey': config['SUPABASE_PUBLISHABLE_KEY']})
    with urlopen(request, timeout=30) as response:
        return json.load(response)


rows = []
for offset in range(0, manifest['records'], 500):
    rows.extend(get(dict(select='id,catalog_exercise_id,animation_url,attribution,source_revision',
                         order='id', offset=offset, limit=500)))
assert len(rows) == manifest['records']
assert len({row['id'] for row in rows}) == manifest['records']
assert sum(row['catalog_exercise_id'] is not None for row in rows) == manifest['mappedMedia']
catalog_ids = {item['id'] for item in json.loads((HERE / 'exercises.json').read_text(encoding='utf-8'))}
assert {row['catalog_exercise_id'] for row in rows} <= catalog_ids
equivalences = json.loads((HERE / 'sources/gymvisual-equivalences.json').read_text(encoding='utf-8'))
by_id = {row['id']: row for row in rows}
assert all(by_id[source_id]['catalog_exercise_id'] == target
           for source_id, target in equivalences.items())
assert all(row['source_revision'] == manifest['revision'] and
           row['animation_url'].endswith('.gif') and
           row['attribution'] == manifest['attribution'] for row in rows)
matched = get(dict(select='id,animation_url', catalog_exercise_id='eq.Barbell_Deadlift'))
assert len(matched) == 1 and matched[0]['animation_url'].endswith('.gif')
searched = get(dict(select='id,name', search_name='ilike.*bench*', limit=20))
assert searched
print(json.dumps({'records': len(rows), 'reviewedEquivalences': len(equivalences),
                  'catalogExercises': len(catalog_ids),
                  'anonymousRead': True, 'searchWorks': True}))
