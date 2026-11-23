"""Render current, hash-bound review coverage from validator evidence."""
import json
from pathlib import Path
HERE=Path(__file__).resolve().parent
BOOK=HERE.parents[1]
final=HERE/'FINAL_VALIDATION.json'
source=final if final.exists() else HERE/'STRUCTURE_AND_PROGRESS.json'
d=json.loads(source.read_text(encoding='utf-8'))
rows=['# 100단원 교차 검토 행렬','',
    '각 판정은 원고의 현재 SHA-256과 연결됩니다. 통과는 모델의 전편 읽기·텍스트 과제 풀이를 뜻하며, 사람 감수·실제 청취·학습자 실측은 포함하지 않습니다. 보고서의 최초 지적은 교정 전 원고에 대한 기록이며, 수정 후 판정은 FINAL 기록을 우선합니다.','',
    f'검사 시각: `{d["checkedUtc"]}`. 검사 모드: `{d["mode"]}`. 구조 문제: {len(d["problems"])}건.','',
    '| 단원 | 현재 SHA-256 앞 12자리 | 한영 | 한독 | 교육과정·과제 |',
    '|---|---|---|---|---|']
unit_order=json.loads((BOOK/'sources/LEVEL_STORY_100.json').read_text(encoding='utf-8'))['units']
for unit in unit_order:
    key=unit['unit_id']
    h=d['finalSha256'][key]
    cells=[]
    for role in ('ko-en','ko-de','curriculum'):
        row=d['reviewCoverage'][role]['units'].get(key)
        if not row:
            cells.append('검토 대기');continue
        status='수정 후 재검토 대기' if row.get('sha256')!=h else ('통과' if row.get('verdict')=='PASS' and row.get('fullTextRead') and row.get('tasksSolvedAsText') else '교정·확인 필요')
        report=Path(row['report']).relative_to('reviews/full-cross-review-20261115').with_suffix('.md').as_posix()
        cells.append(f'[{status}]({report})')
    rows.append(f'| [{key}](../../manuscripts/{key}.md) | `{h[:12]}` | '+ ' | '.join(cells)+' |')
rows+=['','전체 SHA-256, 누락·오래된 판정, 단원별 출처는 [검사 JSON]('+source.name+')에 있습니다.','',
    '서문·집필 기준·용어·서사 연결·재사용 설명·README 6문서도 각 역할의 COMMON 및 COMMON_FINAL 기록에서 별도로 검토합니다.']
p=HERE/'REVIEW_MATRIX.md';t=p.with_suffix('.md.tmp');s='\n'.join(rows)+'\n';t.write_text(s,encoding='utf-8',newline='');assert t.read_text(encoding='utf-8')==s;t.replace(p)
print('Wrote matrix for',len(d['finalSha256']),'units')
