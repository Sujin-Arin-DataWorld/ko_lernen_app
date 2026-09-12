"""Stable source requirement keys and executable, hash-bound objective links.

Unlinked requirements remain in the publication denominator. This is a binding
contract, not a claim that a task proves an entire language skill.
"""
import hashlib
import json


def digest(value):
    return hashlib.sha256(json.dumps(value, ensure_ascii=False, sort_keys=True, separators=(',', ':')).encode()).hexdigest()


def requirements(phases):
    result = []
    for phase in phases:
        def add(key, mode, source, skill=None):
            result.append(dict(id=f"{phase['id']}:objective:{key}:{mode}",
                phaseId=phase['id'], level=phase['level'], sourceRequirementKey=key,
                sourceHash=digest(source), mode=mode, skill=skill))
        for grammar in phase['koreanGrammar']:
            for mode in ('R', 'P'):
                add('grammar/'+grammar['grammarKey'], mode, grammar)
        for skill in ('listening', 'reading', 'speaking', 'writing'):
            for i, row in enumerate(phase[skill]):
                # Core and genre IDs stay stable when other genres are added.
                key=skill+'/'+('genre/'+row['textTypeId'] if row.get('textTypeId') else 'core' if i == 0 else f'additional/{i}')
                add(key, 'P' if skill in ('speaking','writing') else 'R', row, skill)
        for axis in ('functions', 'vocabDomains'):
            for row in phase[axis]:
                for mode in ('R','P'):
                    add(axis+'/'+row['id'], mode, row)
        for i, row in enumerate(phase['phonology']):
            for mode in ('R','P'):
                add(f'phonology/{i}', mode, row)
        for mode, field in [('R','recognitionRegisterIds'),('P','productionRegisterIds')]:
            for register in phase['pragmaticsRegister'][field]:
                add('register/'+register, mode, phase['pragmaticsRegister'])
    if len({r['id'] for r in result}) != len(result):
        raise ValueError('Duplicate source objective ID')
    return result


def build(phases, tasks, ledger):
    if ledger['schemaVersion'] != 1 or ledger['sourceHash'] != digest(phases):
        raise ValueError('Objective source changed; re-review bindings')
    rows = requirements(phases)
    by_objective={r['id']:r for r in rows}
    by_task={t['id']:t for t in tasks}
    linked={r['id']:[] for r in rows}
    seen=set()
    for link in ledger['links']:
        objective=by_objective.get(link['objectiveId'])
        task=by_task.get(link['taskId'])
        if objective is None or task is None or task['phaseId']!=objective['phaseId'] or task['level']!=objective['level'] or task['mode']!=objective['mode']:
            raise ValueError('Invalid objective/task/level/mode binding')
        if objective['skill'] is not None and task['skill'] != objective['skill']:
            raise ValueError('Wrong skill objective binding')
        if link['taskHash']!=task['contentHash'] or link['sourceHash']!=objective['sourceHash'] or link['reviewer']!='Astra' or not link['rationaleKo'].strip():
            raise ValueError('Unreviewed or stale objective binding')
        identity=(objective['id'],task['id'])
        if identity in seen:
            raise ValueError('Duplicate objective link')
        seen.add(identity)
        ids=link['criterionIds']
        available={q['id'] for q in task['assessment']['questions']}
        if len(ids)!=len(set(ids)) or not set(ids)<=available or (not ids and task['skill']!='speaking'):
            raise ValueError('Missing or invalid assessment criterion reference')
        unscored=task['skill']=='speaking' or any(q['kind'] in ('freeText','boundedSentence') for q in task['assessment']['questions'] if q['id'] in ids)
        linked[objective['id']].append(dict(taskId=task['id'], taskHash=task['contentHash'],
            materialIds=[task['id']+'/practice/material',task['id']+'/assessment/material'],
            practiceId=task['id']+'/practice', assessmentId=task['id']+'/assessment',
            criterionIds=ids, evaluationScope='includes_unscored' if unscored else 'structured_only'))
    return [dict(**row, bindings=linked[row['id']],
        coverage='task_path_connected' if linked[row['id']] else 'unverified',
        # Even a deterministic item samples a requirement; it is not proof of
        # full productive/receptive mastery of that grammar/function/domain.
        mastery='unverified') for row in rows]


def report(objectives):
    lines=['# Phase 필수 목표의 실제 연결', '',
        '원본 문법·4기능·장르·기능·어휘 영역·발음·말투 요구를 같은 목록에 유지한다. 연결된 과제는 해당 요구의 연습 경로이며 전체 숙달을 증명하지 않는다.', '',
        'R과 P는 별도다. 자동 채점할 수 없는 필수 응답과 아직 연결하지 않은 요구를 분모에서 제거하지 않는다.', '',
        '| Phase | 필수 요구 | 경로 연결 | 미연결 | 전체 숙달 |', '|---|---:|---:|---:|---|']
    for n in range(1,31):
        phase=f'KP{n:02}'
        rows=[r for r in objectives if r['phaseId']==phase]
        connected=sum(bool(r['bindings']) for r in rows)
        lines.append(f'| {phase} | {len(rows)} | {connected} | {len(rows)-connected} | 미검증 |')
    lines += ['', '## 미연결 요구', '']
    for row in objectives:
        if not row['bindings']:
            lines.append(f"- `{row['id']}`")
    return '\n'.join(lines).rstrip()+'\n'
