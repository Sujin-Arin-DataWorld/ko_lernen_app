"""Verify reviewed quotes against actual dialogue, never grammar declarations."""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path

from tool.curriculum_context_inventory import build_inventory

ROOT = Path(__file__).resolve().parents[1]
LEDGER = Path('tools/content_factory/cefr_matrix/context_evidence_review.json')


def context_hash(passages):
    # Bind all adjacent turns, not merely the selected sentence or file name.
    return hashlib.sha256(json.dumps(passages, ensure_ascii=False,
        sort_keys=True, separators=(',', ':')).encode()).hexdigest()


def audit(root=ROOT):
    phases = json.loads((root / 'tools/content_factory/cefr_matrix/phases.json').read_text(encoding='utf-8'))['phases']
    requirements = {(p['id'], g['grammarKey']): p['level']
                    for p in phases for g in p['koreanGrammar']}
    inventory = build_inventory(root)
    passages = inventory['passages']
    by_pointer = {(p['sourcePath'], p['jsonPointer']): p for p in passages}
    contexts = {}
    for passage in passages:
        contexts.setdefault((passage['sourcePath'], passage['recordId']), []).append(passage)
    ledger = json.loads((root / LEDGER).read_text(encoding='utf-8'))
    if ledger['schemaVersion'] != 1:
        raise ValueError('Unknown context review schema')
    seen, reviews = set(), []
    for row in ledger['reviews']:
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
        reviews.append({**row, 'sameLevel': requirements[requirement] == row['sourceLevel']})
    # Keep every required Phase/grammar pairing, including spirals, in the denominator.
    # No accepted quote does not establish missing content: it stays unverified.
    rows = []
    for (phase, grammar), level in requirements.items():
        matches = [r for r in reviews if (r['phaseId'], r['grammarKey']) == (phase, grammar)]
        accepted = [r for r in matches if r['decision'] == 'accepted']
        rows.append(dict(phaseId=phase, grammarKey=grammar, level=level,
            contextStatus='reviewed_receptive_use' if accepted else 'unverified',
            sameLevelAnchors=sum(r['sameLevel'] for r in accepted),
            otherLevelAnchors=sum(not r['sameLevel'] for r in accepted),
            rejectedCandidates=sum(r['decision'] == 'rejected' for r in matches),
            productiveAssessment='unverified'))
    return dict(schemaVersion=1, reviews=reviews, requirements=rows)


def report(result):
    lines = ['# Phase 문맥 용례 검수', '',
        '실제 대화·지문의 정확한 구절과 앞뒤 맥락 해시를 검증한다. 문법 ID 선언, 제목, 파일명은 용례 근거가 아니다.', '',
        '미검증은 콘텐츠 부재를 뜻하지 않는다. 수용 용례가 있어도 산출 평가·앱 경로가 완성된 것은 아니다. 이 표의 행 수를 신규 제작량으로 사용하지 않는다.', '',
        '| Phase | 문법 요구 키 | 같은 레벨 근거 | 다른 레벨 근거 | 제외 후보 | 산출 평가 |',
        '|---|---|---:|---:|---:|---|']
    for row in result['requirements']:
        lines.append(f"| {row['phaseId']} | {row['grammarKey']} | {row['sameLevelAnchors']} | {row['otherLevelAnchors']} | {row['rejectedCandidates']} | 미검증 |")
    lines += ['', '## 직접 검수한 연결 및 제외 근거', '']
    for r in result['reviews']:
        lines.append(f"- {r['phaseId']} / {r['grammarKey']} / {r['decision']}: `{r['sourcePath']}{r['jsonPointer']}` — “{r['quote']}”. {r['rationaleKo']}")
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
