"""Connect the legacy matrix denominator to reviewed executable Phase paths.

Static publication/route/criterion evidence is never a learner mastery result.
Legacy keyword candidates and draft holdings retain their original provenance.
"""
import json

from tool.build_phase_tasks import build


def attach(root, rows):
    folder = root / 'tools/content_factory/cefr_matrix/phase_content'
    if not folder.exists():
        return  # Historical/fixture corpus without the Phase publication.
    bundle = build(root)  # Checks every task, translation, review and binding hash.
    objectives = {o['id']: o for o in bundle['objectives']}
    tasks = {t['id']: t for t in bundle['tasks']}
    ledger = json.loads((folder / 'matrix_links.json').read_text(encoding='utf-8'))
    if ledger['schemaVersion'] != 1:
        raise ValueError('Unknown matrix Phase binding version')
    by_key = {r['requirementKey']: r for r in rows}
    overrides = {}
    for link in ledger['links']:
        key = link['requirementKey']
        if key in overrides or key not in by_key:
            raise ValueError('Duplicate or unknown matrix requirement')
        row, objective, task = by_key[key], objectives.get(link['objectiveId']), tasks.get(link['taskId'])
        if (not objective or not task or objective['level'] != row['level']
                or objective['mode'] != row['mode'] or link['reviewer'] != 'Astra'
                or not link['rationaleKo'].strip() or link['sourceHash'] != objective['sourceHash']
                or link['taskHash'] != task['contentHash']):
            raise ValueError('Stale or invalid matrix Phase review')
        matching = [b for b in objective['bindings'] if b['taskId'] == task['id']]
        if (not matching or not link['criterionIds']
                or not set(link['criterionIds']) <= set(matching[0]['criterionIds'])):
            raise ValueError('Unreviewed matrix assessment criterion')
        overrides[key] = (objective, {**matching[0], 'criterionIds': link['criterionIds']})
    prefixes = {
        'speechAct': ['functions/'],
        'textType': ['listening/genre/', 'reading/genre/', 'speaking/genre/', 'writing/genre/'],
        'register': ['register/'],
    }
    for row in rows:
        matches = [(o, b) for o in objectives.values()
                   if o['level'] == row['level'] and o['mode'] == row['mode']
                   and o['sourceRequirementKey'] in [p + row['id'] for p in prefixes[row['axis']]]
                   for b in o['bindings']]
        if row['requirementKey'] in overrides:
            matches.append(overrides[row['requirementKey']])
        if not matches:
            continue
        row['taskBindings'] = [dict(objectiveId=o['id'], **b) for o, b in matches]
        row['evidenceStage'] = 'phase_task_path_connected'
        row['assessmentEvidence'] = [dict(taskId=b['taskId'], criterionIds=b['criterionIds'],
            evaluationScope=b['evaluationScope'], kind='authored_criteria_not_learner_attempt') for _, b in matches]
        row['runtimeEvidence'] = [dict(route='/learning-phase/task', phaseId=o['phaseId'],
            taskId=b['taskId'], contentHash=b['taskHash'], kind='published_route_contract_not_device_result') for o, b in matches]
        row['mastery'] = 'unverified'
        row['assessable'] = False
