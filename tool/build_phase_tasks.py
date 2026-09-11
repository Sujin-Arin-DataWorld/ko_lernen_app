"""Publish individually model-reviewed Phase tasks; never infer full coverage."""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def fingerprint(value: dict) -> str:
    return hashlib.sha256(json.dumps(value, ensure_ascii=False, sort_keys=True, separators=(',', ':')).encode()).hexdigest()


def localized(value):
    if not isinstance(value, dict) or any(not isinstance(value.get(k), str) or not value[k].strip() for k in ('ko', 'en', 'de')):
        raise ValueError('Missing localized Phase text')


def validate_task(t):
    for key in ('id', 'phaseId', 'level', 'objectiveId'):
        if not isinstance(t.get(key), str) or not t[key].strip():
            raise ValueError(f'Missing task {key}')
    if not t['id'].startswith(t['phaseId'] + ':') or not t['objectiveId'].startswith(t['phaseId'] + ':'):
        raise ValueError('Task belongs to another Phase')
    if t['skill'] not in ('listening', 'reading', 'writing', 'speaking') or t['mode'] != ('P' if t['skill'] in ('writing', 'speaking') else 'R'):
        raise ValueError('Invalid skill/mode')
    for key in ('contentRevision', 'rubricVersion'):
        if type(t.get(key)) is not int or t[key] < 1:
            raise ValueError('Invalid revision')
    if type(t.get('minimumScore')) not in (float, int) or not 0 < t['minimumScore'] <= 1:
        raise ValueError('Invalid score threshold')
    if t['mode'] == 'P' and t['minimumScore'] < .7:
        raise ValueError('Productive threshold below .7')
    for key in ('title', 'teaching'):
        localized(t[key])
    for key in ('requirementKeys', 'prerequisiteTaskIds', 'examplesKo'):
        if not isinstance(t.get(key), list) or any(not isinstance(v, str) or not v.strip() for v in t[key]) or len(t[key]) != len(set(t[key])):
            raise ValueError('Invalid task references/examples')
    for mode in ('practice', 'assessment'):
        p = t[mode]
        if p['sourceKind'] not in ('text', 'sign', 'form', 'audio') or not isinstance(p['sourceKo'], str) or not p['sourceKo'].strip():
            raise ValueError('Missing task material')
        if t['skill'] == 'listening' and p['sourceKind'] != 'audio':
            raise ValueError('Listening requires audio material')
        questions = p['questions']
        if not isinstance(questions, list) or (not questions and t['skill'] != 'speaking'):
            raise ValueError('Missing assessment questions')
        ids = set()
        for q in questions:
            if not q['id'] or q['id'] in ids or type(q['required']) is not bool:
                raise ValueError('Invalid criterion ID/required flag')
            ids.add(q['id'])
            localized(q['prompt'])
            localized(q['explanation'])
            answers = q['acceptedAnswers']
            if not isinstance(answers, list) or not answers or any(not isinstance(a, str) or not a.strip() for a in answers) or len(answers) != len(set(answers)):
                raise ValueError('Missing/duplicate answers')
            if q['kind'] == 'choice':
                option_ids = [o['id'] for o in q['options']]
                if len(option_ids) < 2 or len(option_ids) != len(set(option_ids)) or not set(answers) < set(option_ids) or any(not o['text'].strip() for o in q['options']):
                    raise ValueError('Invalid answer/distractor')
            elif q['kind'] not in ('field', 'boundedSentence') or q['options']:
                raise ValueError('Invalid response kind')
            if q['kind'] == 'boundedSentence':
                rejected = q.get('rejectedAnswers')
                if not isinstance(rejected, list) or not rejected or any(not isinstance(v, str) or not v.strip() for v in rejected) or set(rejected) & set(answers):
                    raise ValueError('Invalid bounded-sentence contrast')
    if t['practice']['sourceKo'] == t['assessment']['sourceKo']:
        raise ValueError('Assessment reuses practice material')


def build(root: Path) -> dict:
    folder = root / 'tools/content_factory/cefr_matrix/phase_content'
    phases = {p['id']: p for p in json.loads((folder.parent / 'phases.json').read_text(encoding='utf-8'))['phases']}
    tasks, publications, ids, objectives = [], {}, set(), set()
    for source in sorted(folder.glob('kp[0-9][0-9].json')):
        bundle = json.loads(source.read_text(encoding='utf-8'))
        phase = phases[bundle['phaseId']]
        if bundle['schemaVersion'] != 1 or bundle['status'] != 'partial':
            raise ValueError('Full Phase coverage is not certified by this publisher')
        raw_reviews = json.loads(source.with_name(source.stem + '_review.json').read_text(encoding='utf-8'))['reviews']
        reviews = {r['taskId']: r for r in raw_reviews}
        if len(reviews) != len(raw_reviews) or set(reviews) != {t['id'] for t in bundle['tasks']}:
            raise ValueError('Review ledger does not match tasks')
        grammar = {g['grammarKey'] for g in phase['koreanGrammar']}
        for t in bundle['tasks']:
            validate_task(t)
            digest = fingerprint(t)
            review = reviews[t['id']]
            if review['status'] != 'MODEL_QA_PASS' or review['sha256'] != digest or set(review['checks']) != {'KO', 'EN', 'DE', 'answer-rubric'}:
                raise ValueError('Unreviewed or stale task')
            if t['phaseId'] != phase['id'] or t['level'] != phase['level'] or not set(t['requirementKeys']) <= grammar:
                raise ValueError('Task source requirements disagree with Phase')
            if t['id'] in ids or t['objectiveId'] in objectives:
                raise ValueError('Duplicate task/objective')
            ids.add(t['id']); objectives.add(t['objectiveId'])
            tasks.append({**t, 'contentHash': digest})
        publications[phase['id']] = 'partial'
    by_id = {t['id']: t for t in tasks}
    visited, active = set(), set()
    def visit(i):
        if i in active or i not in by_id:
            raise ValueError('Cyclic or missing prerequisite')
        if i in visited:
            return
        active.add(i)
        for ref in by_id[i]['prerequisiteTaskIds']:
            visit(ref)
        active.remove(i); visited.add(i)
    for i in by_id:
        visit(i)
    return {'schemaVersion': 1, 'publications': publications, 'tasks': tasks}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    bundle = build(ROOT)
    result = json.dumps(bundle, ensure_ascii=False, indent=2) + '\n'
    output = ROOT / 'assets/data/phase_tasks.json'
    if args.check:
        if not output.exists() or output.read_text(encoding='utf-8') != result:
            raise SystemExit('Phase tasks are stale')
    else:
        output.write_text(result, encoding='utf-8')
    report = ROOT / 'docs/data/phase_task_coverage_report.md'
    expected_report = coverage_report(ROOT, bundle)
    if args.check:
        if not report.exists() or report.read_text(encoding='utf-8') != expected_report:
            raise SystemExit('Phase task coverage report is stale')
    else:
        report.write_text(expected_report, encoding='utf-8', newline='\n')


def coverage_report(root, bundle):
    phases = json.loads((root / 'tools/content_factory/cefr_matrix/phases.json').read_text(encoding='utf-8'))['phases']
    lines = ['# Phase 실제 과제 연결 범위', '',
        '이 보고서는 발행된 Phase 과제의 연결 범위다. 기존 대화 콘텐츠의 누락 감사나 학습 완성률을 대신하지 않는다.', '',
        '문법은 정확한 원본 키를 분모에 유지한다. 선택형 문법 과제는 수용(R) 연결이며 산출(P) 숙달을 입증하지 않는다. 자유 문장·발화의 미채점 범위를 제외해 완성률을 높이지 않는다.', '',
        '| Phase | 레벨 | 원본 문법 키 | R 연결 키 | P 연결 키 | 과제 | 구조화 채점 과제 | 자유 응답 미검증 | 전체 숙달 |',
        '|---|---|---:|---:|---:|---:|---:|---|---|']
    for phase in phases:
        tasks = [t for t in bundle['tasks'] if t['phaseId'] == phase['id']]
        def keys(mode):
            return {k for t in tasks if t['mode'] == mode for k in t['requirementKeys']}
        unscored = [t['skill'] for t in tasks if t['skill'] == 'speaking' or any(q['kind'] == 'boundedSentence' for q in t['assessment']['questions'])]
        lines.append(f"| {phase['id']} | {phase['level']} | {len(phase['koreanGrammar'])} | {len(keys('R'))} | {len(keys('P'))} | {len(tasks)} | {sum(t['skill'] != 'speaking' for t in tasks)} | {', '.join(unscored) if unscored else 'Phase 전용 경로 미연결'} | 미검증 |")
    lines += ['', '## 남은 검증', '',
        '- KP01: 문법 12개는 설명·예문·선택형 연습/평가에 연결됐다. 모든 문법의 실제 산출 수행을 인증하지 않는다.',
        '- KP01: 표지·명찰 읽기, 소개 듣기, 가상 등록 서식과 소개/부정 문장, 소개·되묻기 녹음을 제공한다. 쓰기는 검수된 문장만 채점하며 다른 자유 표현과 발화 의미는 unscored다.',
        '- KP02–KP30: 기존 관련 대화 경로를 유지한다. 전용 자료·연습·평가의 제작과 연결이 남아 있다.',
        '- W0d2: 기존 원문의 문맥별 근거 연결과 실제 누락 분류가 남아 있다. 이 보고서는 갭 행 수를 제작량으로 변환하지 않는다.',
        '- Android/Web/iOS 실제 기기 QA는 이 정적 보고서가 증명하지 않는다. PR 검증 결과에 별도 기록한다.', '']
    return '\n'.join(lines)


if __name__ == '__main__':
    main()
