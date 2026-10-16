"""Rank possible Gym visual / Portuguese catalog duplicates for human review."""
import json
from collections import defaultdict
from difflib import SequenceMatcher
from pathlib import Path

from build_media import EQUIPMENT, MUSCLES, normalize

HERE = Path(__file__).resolve().parent
catalog = json.loads((HERE / 'exercises.json').read_text(encoding='utf-8'))
original = [item for item in catalog if not item['id'].startswith('gymvisual-')]
new = [item for item in catalog if item['id'].startswith('gymvisual-')]
source = {item['id']: item for item in json.loads((HERE / 'sources/gymvisual-media.json').read_text(encoding='utf-8'))}

index = defaultdict(set)
names = {}
for item in original:
    variants = {normalize(name) for name in item.get('aliases', [])}
    names[item['id']] = variants
    for variant in variants:
        for token in variant.split():
            if len(token) > 2:
                index[token].add(item['id'])
by_id = {item['id']: item for item in original}

results = []
for item in new:
    media = source[item['id'].removeprefix('gymvisual-')]
    query = normalize(media['name'])
    tokens = set(query.split())
    possible = set().union(*(index[token] for token in tokens if len(token) > 2))
    ranked = []
    for candidate_id in possible:
        candidate = by_id[candidate_id]
        score = max((SequenceMatcher(None, query, name).ratio() for name in names[candidate_id]), default=0)
        if score < 0.65:
            continue
        same_equipment = candidate['equipment'] == EQUIPMENT.get(media['equipment'], media['equipment'])
        same_muscle = candidate['muscle'] == MUSCLES.get(media['target'])
        ranked.append((score, same_equipment, same_muscle, candidate_id, candidate['title']))
    ranked.sort(reverse=True)
    if ranked:
        results.append(dict(sourceId=media['id'], english=media['name'],
                            equipment=media['equipment'], target=media['target'],
                            candidates=[dict(score=round(score, 3), sameEquipment=equipment,
                                             sameMuscle=muscle, catalogId=identifier, portuguese=title)
                                        for score, equipment, muscle, identifier, title in ranked[:3]]))

results.sort(key=lambda row: row['candidates'][0]['score'], reverse=True)
out = HERE.parent.parent / '.dart_tool/catalog-media/duplicate-candidates.json'
out.write_text(json.dumps(results, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
print(json.dumps(dict(new=len(new), candidates=len(results), highConfidence=sum(
    row['candidates'][0]['score'] >= 0.86 and row['candidates'][0]['sameEquipment']
    and row['candidates'][0]['sameMuscle'] for row in results), output=str(out))))
