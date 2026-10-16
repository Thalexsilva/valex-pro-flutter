"""Build the Supabase catalog seed from checked-in, pinned public datasets.

Run: python tool/exercise_catalog/generate.py
No network or third-party Python dependencies are required.
"""
import hashlib
import json
import re
import unicodedata
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent.parent


def read(name):
    return json.loads((HERE / 'sources' / name).read_text(encoding='utf-8-sig'))


def normalize(text):
    return re.sub(r'[^a-z0-9]+', '-', ''.join(
        c for c in unicodedata.normalize('NFD', text.lower())
        if unicodedata.category(c) != 'Mn')).strip('-')


MUSCLES = {
    'abdominals': 'Abdômen', 'abductors': 'Abdutores', 'adductors': 'Adutores',
    'biceps': 'Bíceps', 'calves': 'Panturrilha', 'chest': 'Peito',
    'forearms': 'Antebraço', 'glutes': 'Glúteos', 'hamstrings': 'Posterior',
    'lats': 'Costas', 'lower back': 'Lombar', 'middle back': 'Costas',
    'neck': 'Pescoço', 'quadriceps': 'Quadríceps', 'shoulders': 'Ombro',
    'traps': 'Trapézio', 'triceps': 'Tríceps',
}
EQUIPMENT = {
    'bands': 'Elástico', 'barbell': 'Barra', 'body only': 'Peso corporal',
    'cable': 'Polia', 'dumbbell': 'Halteres', 'e-z curl bar': 'Barra W',
    'exercise ball': 'Bola suíça', 'foam roll': 'Rolo de liberação',
    'kettlebells': 'Kettlebell', 'machine': 'Máquina',
    'medicine ball': 'Medicine ball', 'other': 'Outros', None: 'Não informado',
}
LEVELS = {'beginner': 'Iniciante', 'intermediate': 'Intermediário',
          'expert': 'Avançado'}

# Explicit equivalences against the frozen 152-entry legacy snapshot. Ambiguous
# variants remain separate; no fuzzy match silently merges different movements.
LEGACY_EQUIVALENTS = {
    0: 'Butterfly', 1: 'Barbell_Bench_Press_-_Medium_Grip',
    2: 'Barbell_Incline_Bench_Press_-_Medium_Grip',
    3: 'Decline_Barbell_Bench_Press', 4: 'Dumbbell_Bench_Press',
    5: 'Incline_Dumbbell_Press', 6: 'Decline_Dumbbell_Bench_Press',
    7: 'Machine_Bench_Press', 8: 'Leverage_Incline_Chest_Press',
    9: 'Dumbbell_Flyes', 10: 'Incline_Dumbbell_Flyes',
    11: 'Cable_Crossover', 13: 'Low_Cable_Crossover',
    14: 'Incline_Cable_Flye', 15: 'Pushups',
    16: 'Push-Ups_With_Feet_Elevated', 17: 'Dips_-_Chest_Version',
    18: 'Straight-Arm_Dumbbell_Pullover', 19: 'Wide-Grip_Lat_Pulldown',
    20: 'Underhand_Cable_Pulldowns', 21: 'V-Bar_Pulldown',
    24: 'Straight-Arm_Pulldown', 25: 'Seated_Cable_Rows',
    27: 'Bent_Over_Barbell_Row', 28: 'Bent_Over_Two-Dumbbell_Row',
    31: 'Seated_One-arm_Cable_Pulley_Rows', 32: 'One-Arm_Dumbbell_Row',
    33: 'Pullups', 35: 'Barbell_Deadlift', 36: 'Rack_Pulls',
    37: 'Face_Pull', 39: 'Hyperextensions_Back_Extensions',
    41: 'Machine_Shoulder_Military_Press', 42: 'Barbell_Shoulder_Press',
    43: 'Arnold_Dumbbell_Press', 44: 'Dumbbell_Raise',
    45: 'Standing_Low-Pulley_Deltoid_Raise',
    47: 'Front_Dumbbell_Raise', 50: 'Upright_Barbell_Row',
    51: 'Upright_Cable_Row', 53: 'Cable_Rear_Delt_Fly',
    54: 'Reverse_Machine_Flyes', 56: 'Barbell_Shrug', 57: 'Dumbbell_Shrug',
    59: 'Dumbbell_Bicep_Curl', 60: 'Alternate_Incline_Dumbbell_Curl',
    62: 'One_Arm_Dumbbell_Preacher_Curl', 63: 'Machine_Preacher_Curls',
    64: 'Concentration_Curls', 65: 'Standing_Biceps_Cable_Curl',
    66: 'Hammer_Curls', 67: 'Cable_Hammer_Curls_-_Rope_Attachment',
    69: 'Spider_Curl', 70: 'Reverse_Barbell_Curl',
    73: 'Triceps_Pushdown', 74: 'Triceps_Pushdown_-_Rope_Attachment',
    75: 'Triceps_Pushdown_-_V-Bar_Attachment', 76: 'EZ-Bar_Skullcrusher',
    80: 'Bench_Dips', 81: 'Parallel_Bar_Dip', 82: 'Tricep_Dumbbell_Kickback',
    84: 'Close-Grip_Barbell_Bench_Press', 85: 'Barbell_Full_Squat',
    86: 'Front_Barbell_Squat', 87: 'Smith_Machine_Squat', 88: 'Hack_Squat',
    89: 'Leg_Press', 91: 'Leg_Extensions', 93: 'Dumbbell_Lunges',
    97: 'Barbell_Hip_Thrust', 100: 'Plie_Dumbbell_Squat',
    102: 'Thigh_Abductor', 104: 'Thigh_Adductor',
    108: 'Reverse_Hyperextension', 109: 'Stiff-Legged_Barbell_Deadlift',
    110: 'Stiff-Legged_Dumbbell_Deadlift', 111: 'Romanian_Deadlift',
    112: 'Lying_Leg_Curls', 113: 'Seated_Leg_Curl', 116: 'Ball_Leg_Curl',
    117: 'Good_Morning', 120: 'Seated_Calf_Raise',
    122: 'Calf_Press_On_The_Leg_Press_Machine', 124: 'Crunches',
    126: 'Hanging_Leg_Raise', 127: 'Cable_Crunch',
    128: 'Air_Bike', 129: 'Plank', 130: 'Side_Bridge',
    132: 'Ab_Roller', 133: 'Dead_Bug', 134: 'Stomach_Vacuum',
    137: 'Stairmaster', 139: 'Rowing_Stationary',
    140: 'Elliptical_Trainer', 144: 'Rope_Jumping',
    147: 'Freehand_Jump_Squat',
}

# Local PT-BR translations for the three records newer than the PT snapshot.
TRANSLATIONS = {
    'Kettlebell_Halo': {
        'name': 'Halo com kettlebell',
        'instructions': [
            'Fique em pé com os pés na largura do quadril. Segure o kettlebell invertido pelas alças, próximo ao peito. Contraia o abdômen e os glúteos, mantendo as costelas baixas.',
            'Com os cotovelos próximos à cabeça, leve o kettlebell junto a uma orelha e por trás da cabeça.',
            'Continue o círculo pela outra orelha e volte à posição inicial, mantendo o peso próximo ao corpo.',
            'Complete os círculos prescritos em uma direção e repita a mesma quantidade na direção contrária.',
            'Mova-se devagar e mantenha cabeça, quadril e lombar estáveis. Reduza a carga se arquear a lombar ou afastar muito o peso da cabeça.',
        ],
    },
    'Kettlebell_Halo_With_Overhead_Extension': {
        'name': 'Halo com kettlebell e extensão acima da cabeça',
        'instructions': [
            'Fique em pé com os pés na largura do quadril. Segure o kettlebell invertido pelas alças, perto do peito, com abdômen e glúteos contraídos.',
            'Leve o peso junto a uma orelha até atrás da cabeça e pause, mantendo os cotovelos próximos à cabeça.',
            'Estenda os cotovelos para elevar o kettlebell acima da cabeça, mantendo a parte superior dos braços ao lado dela.',
            'Flexione os cotovelos e baixe o peso com controle até a posição atrás da cabeça.',
            'Complete o círculo pela outra orelha e volte à frente do peito para concluir uma repetição.',
            'Alterne a direção a cada repetição. Mantenha cabeça, quadril e lombar estáveis. Reduza a carga ou separe os movimentos se precisar inclinar o tronco para trás.',
        ],
    },
    'Kettlebell_Overhead_Triceps_Extension': {
        'name': 'Extensão de tríceps acima da cabeça com kettlebell',
        'instructions': [
            'Fique em pé com os pés na largura do quadril. Segure o kettlebell pelas alças com as duas mãos e eleve-o acima da cabeça com os braços estendidos.',
            'Contraia o abdômen e mantenha a parte superior dos braços vertical, próxima à cabeça.',
            'Flexione os cotovelos para baixar o peso atrás da cabeça dentro da sua mobilidade, sem abrir os cotovelos para os lados.',
            'Estenda os cotovelos para voltar à posição inicial, mantendo a parte superior dos braços estável.',
            'Mantenha as costelas baixas e evite arquear a lombar durante a extensão.',
        ],
    },
}

# Distinguish homonyms in the translation using the original movement IDs.
TITLE_OVERRIDES = {
    'Bench_Press_with_Chains': 'Supino com barra e correntes',
    'Chain_Press': 'Supino com correntes nas mãos',
    'Dumbbell_Lunges': 'Afundo com halteres (com passo)',
    'Split_Squat_with_Dumbbells': 'Agachamento dividido com halteres (base fixa)',
    'Jogging_Treadmill': 'Trote na esteira',
    'Running_Treadmill': 'Corrida na esteira',
    'Power_Clean_from_Blocks': 'Power clean a partir de blocos',
    'Snatch_from_Blocks': 'Arranco a partir de blocos',
}


def brief(instructions):
    if not instructions:
        return 'Orientações de execução não fornecidas pela fonte.'
    first = re.split(r'(?<=[.!?])\s+', instructions[0])[0]
    if len(first) <= 220:
        return first
    return first[:217].rsplit(' ', 1)[0] + '…'


def infer_equipment(title):
    text = normalize(title)
    for words, label in [
        (['maquina', 'articulad', 'leg-press', 'extensora', 'flexora', 'hack-squat'], 'Máquina'),
        (['polia', 'cabo', 'pulldown'], 'Polia'),
        (['haltere'], 'Halteres'), (['barra-w'], 'Barra W'),
        (['barra', 'smith'], 'Barra'), (['bola-suica'], 'Bola suíça'),
    ]:
        if any(word in text for word in words):
            return label
    if any(word in text for word in ['prancha', 'flexao', 'abdominal', 'burpee', 'mountain-climber', 'mobilidade', 'polichinelo', 'vacuum']):
        return 'Peso corporal'
    return 'Não informado'


def build():
    originals = read('exercises-en.json')
    translations = {x['id']: x for x in read('exercises-ptbr.json')}
    original_ids = {x['id'] for x in originals}
    assert len(original_ids) == len(originals), 'Duplicate upstream IDs'
    assert set(LEGACY_EQUIVALENTS.values()) <= original_ids, sorted(set(LEGACY_EQUIVALENTS.values()) - original_ids)
    assert len(set(LEGACY_EQUIVALENTS.values())) == len(LEGACY_EQUIVALENTS)
    assert set(translations) <= original_ids
    entries = {}
    for original in originals:
        identifier = original['id']
        pt = translations.get(identifier) or TRANSLATIONS[identifier]
        title = TITLE_OVERRIDES.get(identifier, pt['name'])
        instructions = pt['instructions']
        assert title.strip() and all(step.strip() for step in instructions)
        category = original['category']
        primary = list(dict.fromkeys(MUSCLES[x] for x in original['primaryMuscles']))
        entries[identifier] = dict(
            id=identifier, title=title,
            muscle='Cardio' if category == 'cardio' else primary[0],
            cue=brief(instructions), equipment=EQUIPMENT[original.get('equipment')],
            level=LEVELS[original['level']], category=category,
            source=('Exercícios BD PT-BR · Free Exercise DB' if identifier in translations
                    else 'Free Exercise DB · tradução VALEX'),
            language='pt-BR', instructions=instructions, primaryMuscles=primary,
            secondaryMuscles=list(dict.fromkeys(MUSCLES[x] for x in original['secondaryMuscles'])),
            aliases=list(dict.fromkeys([pt['name'], original['name']])),
        )
    result = []
    for index, legacy in enumerate(read('legacy.json')):
        identifier = LEGACY_EQUIVALENTS.get(index)
        # Exact unambiguous titles may be safely merged too.
        if identifier is None:
            matches = [key for key, value in entries.items()
                       if normalize(value['title']) == normalize(legacy['title'])]
            if len(matches) == 1:
                identifier = matches[0]
        if identifier:
            entry = entries.pop(identifier)
            entry['aliases'] = list(dict.fromkeys([*entry['aliases'], entry['title']]))
            entry.update(legacy)
            if not entry['instructions']:
                entry['instructions'] = [legacy['cue']]
        else:
            category = 'cardio' if legacy['muscle'] == 'Cardio' else (
                'stretching' if legacy['title'].startswith('Mobilidade') else 'strength')
            entry = dict(id='valex-' + normalize(legacy['title']), **legacy,
                         equipment=infer_equipment(legacy['title']),
                         category=category, instructions=[legacy['cue']],
                         primaryMuscles=[legacy['muscle']])
        result.append(entry)
    result.extend(sorted(entries.values(), key=lambda x: normalize(x['title'])))
    ids = [entry['id'] for entry in result]
    titles = [normalize(entry['title']) for entry in result]
    assert len(ids) == len(set(ids)), 'Duplicate catalog IDs'
    assert len(titles) == len(set(titles)), 'Duplicate display titles'
    assert original_ids <= set(ids), 'Lost an upstream exercise'
    output = HERE / 'exercises.json'
    output.write_text(json.dumps(result, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    manifest = {
        'originalCount': len(originals), 'translatedCount': len(translations),
        'localTranslations': list(TRANSLATIONS), 'legacyCount': 152,
        'catalogCount': len(result), 'legacyMergedCount': len(originals) + 152 - len(result),
        'snapshots': {p.name: hashlib.sha256(p.read_bytes()).hexdigest()
                      for p in sorted((HERE / 'sources').glob('*.json'))},
    }
    (HERE / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n', encoding='utf-8')
    print(json.dumps(manifest, indent=2))


if __name__ == '__main__':
    build()
