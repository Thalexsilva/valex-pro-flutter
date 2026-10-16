"""Read-only verification of the public catalog against the checked-in seed."""
import json
from pathlib import Path
from urllib.parse import urlencode
from urllib.request import Request, urlopen

HERE = Path(__file__).resolve().parent
config = json.loads((HERE.parent.parent / 'config/beta.json').read_text(encoding='utf-8-sig'))

def get(table, parameters):
    request = Request(config['SUPABASE_URL'] + '/rest/v1/' + table + '?' + urlencode(parameters),
                      headers={'apikey': config['SUPABASE_PUBLISHABLE_KEY']})
    with urlopen(request, timeout=30) as response:
        return json.load(response)

release, = get('catalog_releases', dict(select='version,exercise_count,method_count', active='eq.true'))
expected = json.loads((HERE / 'exercises.json').read_text(encoding='utf-8'))
rows = []
for offset in range(0, release['exercise_count'], 500):
    rows.extend(get('catalog_exercises', dict(select='summary,instructions',
        release_version='eq.' + release['version'], order='sort_order', offset=offset, limit=500)))
actual = [dict(row['summary'], instructions=row['instructions']) for row in rows]
assert actual == expected, 'Remote exercise content differs from the canonical seed'
assert all('instructions' not in row['summary'] for row in rows)
method_rows = get('catalog_training_methods', dict(select='content',
    release_version='eq.' + release['version'], order='sort_order'))
methods = json.loads((HERE / 'training-methods.json').read_text(encoding='utf-8'))
assert [row['content'] for row in method_rows] == methods
assert len(actual) == release['exercise_count'] == len(expected)
assert len(method_rows) == release['method_count'] == len(methods)
print(json.dumps(dict(version=release['version'], exercises=len(actual), methods=len(methods),
    exact_content_match=True, anonymous_read=True, instructions_separate=True)))
