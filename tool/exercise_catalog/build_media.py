"""Pin Gym visual metadata and prepare backend-only media seed batches.

`--refresh` updates the local metadata snapshot from the pinned GitHub revision.
The Flutter bundle contains neither this snapshot nor any image/GIF files.
"""
import json
import re
import sys
import unicodedata
from pathlib import Path
from urllib.request import Request, urlopen

HERE = Path(__file__).resolve().parent
REVISION = '7455efae41b330c265e7cd4b78dfa848e7ce5ebd'
BASE = f'https://raw.githubusercontent.com/hasaneyldrm/exercises-dataset/{REVISION}/'
ATTRIBUTION = '© Gym visual — https://gymvisual.com/'
SNAPSHOT = HERE / 'sources/gymvisual-media.json'
OUT = HERE.parent.parent / '.dart_tool/catalog-media' / REVISION[:12]
LINK_MIGRATION = HERE.parent.parent.parent / 'supabase/migrations/20260927120100_link_new_exercise_media.sql'

MUSCLES = {
    'abs': 'Abdômen', 'pectorals': 'Peito', 'biceps': 'Bíceps',
    'glutes': 'Glúteos', 'delts': 'Ombros', 'triceps': 'Tríceps',
    'upper back': 'Costas', 'lats': 'Costas', 'calves': 'Panturrilhas',
    'quads': 'Quadríceps', 'forearms': 'Antebraços',
    'cardiovascular system': 'Cardio', 'hamstrings': 'Posteriores',
    'spine': 'Lombar', 'traps': 'Trapézio', 'adductors': 'Adutores',
    'serratus anterior': 'Peito', 'abductors': 'Abdutores',
    'levator scapulae': 'Trapézio',
}
EQUIPMENT = {
    'body weight': 'Peso corporal', 'dumbbell': 'Halteres',
    'cable': 'Polia', 'barbell': 'Barra', 'leverage machine': 'Máquina',
    'band': 'Faixa elástica', 'smith machine': 'Smith',
    'kettlebell': 'Kettlebell', 'weighted': 'Peso adicional',
    'stability ball': 'Bola suíça', 'ez barbell': 'Barra W',
    'resistance band': 'Faixa elástica',
}


def normalize(value):
    ascii_text = unicodedata.normalize('NFKD', value.lower()).encode('ascii', 'ignore').decode()
    return re.sub(r'[^a-z0-9]+', ' ', ascii_text).strip()


def refresh():
    request = Request(BASE + 'data/exercises.json', headers={'User-Agent': 'VALEX-catalog'})
    with urlopen(request, timeout=60) as response:
        source = json.load(response)
    fields = ('id', 'name', 'equipment', 'image', 'gif_url', 'category',
              'target', 'secondary_muscles')
    records = [dict({key: item[key] for key in fields},
                    instructions=item['instruction_steps']['en']) for item in source]
    SNAPSHOT.write_text(json.dumps(records, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')


def literal(data):
    value = json.dumps(data, ensure_ascii=False, separators=(',', ':'))
    assert '$media$' not in value
    return '$media$' + value + '$media$::jsonb'


def build():
    catalog = json.loads((HERE / 'exercises.json').read_text(encoding='utf-8'))
    catalog = [item for item in catalog if not item['id'].startswith('gymvisual-')]
    assert len(catalog) == 931
    source = json.loads(SNAPSHOT.read_text(encoding='utf-8'))
    assert len(source) == 1324 and len({item['id'] for item in source}) == 1324
    aliases = {}
    for item in catalog:
        for name in item.get('aliases', []):
            aliases.setdefault(normalize(name), set()).add(item['id'])
    matches = {}
    for item in source:
        candidates = aliases.get(normalize(item['name']), set())
        if len(candidates) == 1:
            matches[item['id']] = next(iter(candidates))
    # An ambiguous catalog movement never receives an automatic demonstration.
    reverse = {}
    for source_id, catalog_id in matches.items():
        reverse.setdefault(catalog_id, []).append(source_id)
    matches = {source_id: catalog_id for source_id, catalog_id in matches.items()
               if len(reverse[catalog_id]) == 1}
    used_titles = {normalize(item['title']) for item in catalog}
    added = []
    for item in source:
        if item['id'] in matches:
            continue
        title = item['name'].strip()
        title = title[:1].upper() + title[1:]
        if normalize(title) in used_titles:
            title += f" ({item['equipment']})"
        if normalize(title) in used_titles:
            title += f" #{item['id']}"
        used_titles.add(normalize(title))
        instructions = [step.strip() for step in item['instructions'] if step.strip()]
        assert instructions and item['target'] in MUSCLES, item['id']
        muscle = MUSCLES[item['target']]
        added.append(dict(
            id='gymvisual-' + item['id'], title=title, muscle=muscle,
            cue=instructions[0], equipment=EQUIPMENT.get(item['equipment'], item['equipment']),
            level='Não informado', category='cardio' if item['category'] == 'cardio' else 'strength',
            source='exercises-dataset · Gym visual', language='en',
            instructions=instructions, primaryMuscles=[muscle],
            secondaryMuscles=list(dict.fromkeys(MUSCLES[x] for x in item['secondary_muscles'] if x in MUSCLES)),
            aliases=[item['name']],
        ))
    catalog.extend(added)
    assert len(catalog) == 931 + len(added)
    assert len(used_titles) == len(catalog)
    (HERE / 'exercises.json').write_text(json.dumps(catalog, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    catalog_manifest = json.loads((HERE / 'manifest.json').read_text(encoding='utf-8'))
    catalog_manifest.update(catalogCount=len(catalog), gymvisualAddedCount=len(added),
                            gymvisualExistingMatches=len(matches), gymvisualRevision=REVISION)
    (HERE / 'manifest.json').write_text(json.dumps(catalog_manifest, indent=2) + '\n', encoding='utf-8')

    records = []
    for item in source:
        assert re.fullmatch(r'images/[A-Za-z0-9_-]+\.jpg', item['image'])
        assert re.fullmatch(r'videos/[A-Za-z0-9_-]+\.gif', item['gif_url'])
        records.append(dict(
            id=item['id'], name=item['name'], search_name=normalize(item['name']),
            equipment=item['equipment'], catalog_exercise_id=matches.get(item['id'], 'gymvisual-' + item['id']),
            thumbnail_url=BASE + item['image'], animation_url=BASE + item['gif_url'],
            attribution=ATTRIBUTION, source_revision=REVISION,
        ))
    OUT.mkdir(parents=True, exist_ok=True)
    for batch, start in enumerate(range(0, len(records), 100), 1):
        rows = records[start:start + 100]
        (OUT / f'{batch:03}-media.sql').write_text(
            "insert into public.catalog_exercise_media "
            "(id, name, search_name, equipment, catalog_exercise_id, thumbnail_url, animation_url, attribution, source_revision)\n"
            "select row->>'id', row->>'name', row->>'search_name', row->>'equipment', "
            "row->>'catalog_exercise_id', row->>'thumbnail_url', row->>'animation_url', "
            "row->>'attribution', row->>'source_revision'\n"
            f"from jsonb_array_elements({literal(rows)}) as row\n"
            "on conflict (id) do update set name=excluded.name, search_name=excluded.search_name, "
            "equipment=excluded.equipment, catalog_exercise_id=excluded.catalog_exercise_id, "
            "thumbnail_url=excluded.thumbnail_url, animation_url=excluded.animation_url, "
            "attribution=excluded.attribution, source_revision=excluded.source_revision;\n",
            encoding='utf-8',
        )
    LINK_MIGRATION.write_text(
        '-- Link previously unmatched GIFs to newly imported catalog exercises.\n'
        "update public.catalog_exercise_media set catalog_exercise_id='gymvisual-' || id\n"
        f"where source_revision='{REVISION}' and catalog_exercise_id is null;\n"
        "do $verify$ begin\n"
        f"  if (select count(*) from public.catalog_exercise_media where source_revision='{REVISION}'\n"
        "      and catalog_exercise_id is not null) <> 1324 then\n"
        "    raise exception 'Incomplete media links';\n"
        "  end if;\nend $verify$;\n",
        encoding='utf-8',
    )
    (OUT / 'manifest.json').write_text(json.dumps({
        'revision': REVISION, 'records': len(records), 'automaticMatches': len(matches),
        'newExercises': len(added), 'mappedMedia': len(records),
        'attribution': ATTRIBUTION,
    }, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print(json.dumps({'records': len(records), 'automaticMatches': len(matches),
                      'newExercises': len(added), 'catalogCount': len(catalog), 'output': str(OUT)}))


if __name__ == '__main__':
    if '--refresh' in sys.argv:
        refresh()
    build()
