"""Index manuscript drafts only; never build or modify the application."""
from pathlib import Path
import json,hashlib
BASE=Path(__file__).resolve().parent
story=json.loads((BASE/'sources/LEVEL_STORY_100.json').read_text(encoding='utf-8'))
rows=[]
for u in story['units']:
    p=BASE/'manuscripts'/f"{u['unit_id']}.md"
    rows.append(dict(unitId=u['unit_id'],band=u['band'],title=u['original_title'],
      storyTitle=u['scene_title'],gate=u['spoiler_gate']['this_scene_gate'],
      manuscript=p.relative_to(BASE).as_posix(),
      sha256=hashlib.sha256(p.read_bytes()).hexdigest() if p.exists() else None,
      status='AUTHOR_DRAFT_PENDING_INDEPENDENT_REVIEW' if p.exists() else 'AUTHORING_PENDING'))
out=['# 단원별 원고\n','초고 파일이 있어도 독립 언어 검토·최종 편집 완료를 뜻하지 않습니다. 아래 상태는 집필 파일의 존재만 확인합니다.\n',
 '| 구간 | 단원 | 학습 제목 | 이야기 장면 | 집필 상태 |','|---|---|---|---|---|']
for r in rows:
    label=f"[{r['unitId']}]({r['manuscript']})" if r['sha256'] else r['unitId']
    out.append(f"| {r['band']} | {label} | {r['title']} | {r['storyTitle']} | {'초고 있음 · 검토 기록 별도' if r['sha256'] else '집필 대기'} |")
(BASE/'INDEX.md').write_text('\n'.join(out)+'\n',encoding='utf-8')
(BASE/'MANUSCRIPT_INDEX.json').write_text(json.dumps(dict(appMutationAllowed=False,synthesisAllowed=False,units=rows),ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps(dict(units=len(rows),drafts=sum(r['sha256'] is not None for r in rows),independentApprovalNotInferred=True)))
