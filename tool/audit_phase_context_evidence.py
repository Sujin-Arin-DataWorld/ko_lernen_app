"""Verify reviewed quotes against actual dialogue, never grammar declarations."""
from __future__ import annotations

import argparse
import hashlib
import json
import re
from pathlib import Path

from tool.curriculum_context_inventory import build_inventory
from tool.build_phase_tasks import fingerprint, validate_task

ROOT = Path(__file__).resolve().parents[1]
LEDGER = Path('tools/content_factory/cefr_matrix/context_evidence_review.json')


def context_hash(passages):
    # Bind all adjacent turns, not merely the selected sentence or file name.
    return hashlib.sha256(json.dumps(passages, ensure_ascii=False,
        sort_keys=True, separators=(',', ':')).encode()).hexdigest()


def validate_source_revalidation(row):
    """Keep the first review's attribution distinct from a current source check."""
    original = row.get('originalReview')
    current = row.get('sourceRevalidation')
    if original is None and current is None:
        return
    identity = ('phaseId', 'grammarKey', 'sourcePath', 'recordId', 'jsonPointer',
                'sourceLevel', 'decision', 'mode', 'reviewer', 'status')
    if (not isinstance(original, dict) or not isinstance(current, dict)
            or any(original.get(key) != row.get(key) for key in identity)
            or original.get('reviewer') != 'Astra'
            or original.get('status') != 'MODEL_QA_PASS'
            or not isinstance(original.get('quote'), str) or not original['quote'].strip()
            or not re.fullmatch(r'[0-9a-f]{64}', str(original.get('contextSha256', '')))
            or current.get('reviewer') != 'Codex'
            or current.get('status') != 'MODEL_QA_PASS'
            or not re.fullmatch(r'\d{4}-\d{2}-\d{2}', str(current.get('reviewedOn', '')))
            or not isinstance(current.get('checks'), list)
            or any(not isinstance(check, str) for check in current['checks'])
            or set(current['checks']) != {'exact-quote', 'adjacent-context', 'grammar-function'}
            or current.get('previousContextSha256') != original['contextSha256']
            or current.get('contextSha256') != row['contextSha256']
            or current.get('quote') != row['quote']):
        raise ValueError('Invalid source revalidation provenance')


def reviewed_phase_passages(root):
    """Read actual approved receptive materials, never titles or declared keys.

    Keep this provenance separate from legacy scenario/media reuse. A reviewed
    task still needs an explicit exact-quote decision in the context ledger.
    """
    folder = root / 'tools/content_factory/cefr_matrix/phase_content'
    passages = []
    for path in sorted(folder.glob('kp[0-9][0-9].json')):
        if not path.resolve().is_relative_to(root.resolve()):
            raise ValueError('Phase source escapes repository')
        source = json.loads(path.read_text(encoding='utf-8'))
        review_path = path.with_name(path.stem + '_review.json')
        if not review_path.exists():
            continue
        if not review_path.resolve().is_relative_to(root.resolve()):
            raise ValueError('Phase review escapes repository')
        reviews = {r['taskId']: r for r in json.loads(review_path.read_text(encoding='utf-8'))['reviews']}
        for index, task in enumerate(source['tasks']):
            review = reviews.get(task['id'])
            if review is None or review.get('status') != 'MODEL_QA_PASS':
                continue
            if (review.get('reviewer') != 'Astra' or review.get('sha256') != fingerprint(task)
                    or not {'KO', 'EN', 'DE', 'answer-rubric'} <= set(review.get('checks', []))):
                raise ValueError('Stale Phase source review')
            validate_task(task)
            if task['mode'] != 'R':
                continue
            for mode in ('practice', 'assessment'):
                passages.append(dict(sourcePath=path.relative_to(root).as_posix(),
                    recordId=task['id'], level=task['level'],
                    jsonPointer=f'/tasks/{index}/{mode}/sourceKo',
                    text=task[mode]['sourceKo'], provenance='authored_phase_material'))
    return passages


def audit(root=ROOT):
    phases = json.loads((root / 'tools/content_factory/cefr_matrix/phases.json').read_text(encoding='utf-8'))['phases']
    requirements = {(p['id'], g['grammarKey']): p['level']
                    for p in phases for g in p['koreanGrammar']}
    inventory = build_inventory(root)
    passages = inventory['passages'] + reviewed_phase_passages(root)
    by_pointer = {(p['sourcePath'], p['jsonPointer']): p for p in passages}
    contexts = {}
    for passage in passages:
        contexts.setdefault((passage['sourcePath'], passage['recordId']), []).append(passage)
    ledger = json.loads((root / LEDGER).read_text(encoding='utf-8'))
    if ledger['schemaVersion'] != 1:
        raise ValueError('Unknown context review schema')
    seen, reviews = set(), []
    for row in ledger['reviews']:
        validate_source_revalidation(row)
        identity = (row['phaseId'], row['grammarKey'], row['sourcePath'], row['jsonPointer'])
        if identity in seen:
            raise ValueError('Duplicate context review')
        seen.add(identity)
        requirement = (row['phaseId'], row['grammarKey'])
        if requirement not in requirements:
            raise ValueError('Unknown Phase grammar requirement')
        passage = by_pointer.get((row['sourcePath'], row['jsonPointer']))
        if passage is None or passage['recordId'] != row['recordId']:
            raise ValueError('Review does not reference an actual passage')
        if passage['level'].upper() != row['sourceLevel']:
            raise ValueError('Source level changed')
        if not isinstance(row['quote'], str) or not row['quote'].strip() or row['quote'] not in passage['text']:
            raise ValueError('Quote is absent from the exact passage')
        if row['contextSha256'] != context_hash(contexts[(row['sourcePath'], row['recordId'])]):
            raise ValueError('Adjacent source context changed; re-review required')
        if row['decision'] not in ('accepted', 'rejected') or row['reviewer'] != 'Astra' or row['status'] != 'MODEL_QA_PASS':
            raise ValueError('Unreviewed contextual claim')
        if row['mode'] != 'R' or not isinstance(row['rationaleKo'], str) or not row['rationaleKo'].strip():
            raise ValueError('Reading a source is not productive assessment evidence')
        reviews.append({**row, 'sameLevel': requirements[requirement] == row['sourceLevel'],
            'provenance': passage.get('provenance', 'legacy_scenario_or_media')})
    # Keep every required Phase/grammar pairing, including spirals, in the denominator.
    # No accepted quote does not establish missing content: it stays unverified.
    rows = []
    for (phase, grammar), level in requirements.items():
        matches = [r for r in reviews if (r['phaseId'], r['grammarKey']) == (phase, grammar)]
        accepted = [r for r in matches if r['decision'] == 'accepted']
        legacy = [r for r in accepted if r['provenance'] == 'legacy_scenario_or_media']
        authored = [r for r in accepted if r['provenance'] == 'authored_phase_material']
        rows.append(dict(phaseId=phase, grammarKey=grammar, level=level,
            contextStatus='reviewed_receptive_use' if accepted else 'unverified',
            sameLevelAnchors=sum(r['sameLevel'] for r in accepted),
            otherLevelAnchors=sum(not r['sameLevel'] for r in accepted),
            rejectedCandidates=sum(r['decision'] == 'rejected' for r in matches),
            legacyReuseStatus='reviewed_receptive_use' if legacy else 'unverified_not_proven_missing',
            legacyAnchors=len(legacy), authoredPhaseAnchors=len(authored),
            contentDisposition=('reviewed_legacy_source_available' if legacy else
                'reviewed_new_phase_source' if authored else 'source_review_required'),
            productiveAssessment='unverified'))
    withdrawn = ledger.get('withdrawnReviews', [])
    if not isinstance(withdrawn, list) or any(
            not isinstance(row, dict) or row.get('status') != 'SOURCE_SUPERSEDED'
            or not isinstance(row.get('originalReview'), dict)
            or row['originalReview'].get('reviewer') != 'Astra'
            or row['originalReview'].get('status') != 'MODEL_QA_PASS'
            or not re.fullmatch(r'\d{4}-\d{2}-\d{2}', str(row.get('withdrawnOn', '')))
            or row.get('reviewer') != 'Codex'
            or row.get('reason') != 'reviewed_source_changed'
            for row in withdrawn):
        raise ValueError('Invalid withdrawn source review provenance')
    return dict(schemaVersion=1, reviews=reviews, requirements=rows,
                withdrawnReviews=withdrawn)


def report(result):
    lines = ['# Phase 문맥 용례 검수', '',
        '실제 대화·지문의 정확한 구절과 앞뒤 맥락 해시를 검증한다. 문법 ID 선언, 제목, 파일명은 용례 근거가 아니다.', '',
        '미검증은 콘텐츠 부재를 뜻하지 않는다. 수용 용례가 있어도 산출 평가·앱 경로가 완성된 것은 아니다. 이 표의 행 수를 신규 제작량으로 사용하지 않는다.', '',
        '신규 Phase 원문과 기존 대화·미디어 재사용 근거를 구별한다. 신규 원문의 검수는 과거 콘텐츠에 이미 있었다는 뜻이 아니다.', '',
        '## 레벨별 원문 근거와 남은 평가 범위', '',
        '| 레벨 | Phase 문법 요구 | 원문 근거 확인 | 기존 원문 근거가 있는 요구 | 신규 원문으로 확인한 요구 | 산출 전체 의미 |',
        '|---|---:|---:|---:|---:|---|']
    for level in ('A1', 'A2', 'B1', 'B2', 'C1', 'C2'):
        rows = [r for r in result['requirements'] if r['level'] == level]
        lines.append(f"| {level} | {len(rows)} | {sum(r['contextStatus']=='reviewed_receptive_use' for r in rows)} | {sum(r['legacyAnchors']>0 for r in rows)} | {sum(r['authoredPhaseAnchors']>0 for r in rows)} | 미검증 |")
    lines += ['', '기존·신규 근거가 함께 있는 요구는 두 열에 각각 나타난다. 기존 근거 미검증은 신규 콘텐츠가 없다는 뜻이 아니다. 제외 후보는 정확한 형태·의미가 다른 경우로 따로 남긴다. 문법 카드 대응 오류는 기존 매트릭스의 검수된 대응표를, 실제 실행 경로는 목표 연결 보고서를 함께 확인한다.', '',
        '| Phase | 문법 요구 키 | 같은 레벨 근거 | 다른 레벨 근거 | 제외 후보 | 산출 평가 |',
        '|---|---|---:|---:|---:|---|']
    for row in result['requirements']:
        lines.append(f"| {row['phaseId']} | {row['grammarKey']} | {row['sameLevelAnchors']} | {row['otherLevelAnchors']} | {row['rejectedCandidates']} | 미검증 |")
    lines += ['', '## 직접 검수한 연결 및 제외 근거', '']
    for r in result['reviews']:
        attribution = ''
        if current := r.get('sourceRevalidation'):
            attribution = (f" 최초 검수: {r['originalReview']['reviewer']}; 현재 원문 재대조: "
                           f"{current['reviewer']} ({current['status']}, {current['reviewedOn']}).")
        lines.append(f"- {r['phaseId']} / {r['grammarKey']} / {r['decision']} / {r['provenance']}: `{r['sourcePath']}{r['jsonPointer']}` — “{r['quote']}”. {r['rationaleKo']}{attribution}")
    if withdrawn := result.get('withdrawnReviews'):
        lines += ['', '## 원문 수정으로 철회한 과거 근거', '',
                  '아래 과거 검수는 이력으로만 보존하며 현재 수용 용례나 제외 후보 수에 포함하지 않는다.', '']
        for r in withdrawn:
            original = r['originalReview']
            lines.append(f"- {original['phaseId']} / {original['grammarKey']} / {original['recordId']}: "
                         f"{r['status']} ({r['withdrawnOn']}); 최초 검수: {original['reviewer']}.")
    return '\n'.join(lines) + '\n'


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    result = audit()
    targets = {
        ROOT / 'docs/data/phase_context_evidence_report.json': json.dumps(result, ensure_ascii=False, indent=2) + '\n',
        ROOT / 'docs/data/phase_context_evidence_report.md': report(result),
    }
    for path, content in targets.items():
        if args.check:
            if not path.exists() or path.read_text(encoding='utf-8') != content:
                raise SystemExit(f'Stale context evidence report: {path.name}')
        else:
            path.write_text(content, encoding='utf-8', newline='\n')


if __name__ == '__main__':
    main()
