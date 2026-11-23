"""Index manuscripts and exact-hash review evidence; never modify the app."""
from pathlib import Path
import json,hashlib
BASE=Path(__file__).resolve().parent
story=json.loads((BASE/'sources/LEVEL_STORY_100.json').read_text(encoding='utf-8'))
proof_path=BASE/'reviews/full-cross-review-20261115/FINAL_VALIDATION.json'
proof=json.loads(proof_path.read_text(encoding='utf-8')) if proof_path.exists() else {}
def reviewed(unit_id, digest):
    if proof.get('problems') != [] or proof.get('finalSha256',{}).get(unit_id) != digest:
        return False
    for role in ('ko-en','ko-de','curriculum'):
        row=proof.get('reviewCoverage',{}).get(role,{}).get('units',{}).get(unit_id,{})
        if row.get('sha256') != digest or row.get('verdict') != 'PASS' or not row.get('fullTextRead') or not row.get('tasksSolvedAsText'):
            return False
    return True

def atomic_write(path, text):
    temporary=path.with_suffix(path.suffix+'.tmp')
    previous=path.read_bytes() if path.exists() else b''
    content=text.replace('\r\n','\n')
    if previous.count(b'\r\n') and previous.count(b'\r\n') == previous.count(b'\n'):
        content=content.replace('\n','\r\n')
    temporary.write_bytes(content.encode('utf-8'))
    assert temporary.read_text(encoding='utf-8') == text
    temporary.replace(path)

rows=[]
for u in story['units']:
    p=BASE/'manuscripts'/f"{u['unit_id']}.md"
    digest=hashlib.sha256(p.read_bytes()).hexdigest() if p.exists() else None
    checked=reviewed(u['unit_id'],digest) if digest else False
    rows.append(dict(unitId=u['unit_id'],band=u['band'],title=u['original_title'],
      storyTitle=u['scene_title'],gate=u['spoiler_gate']['this_scene_gate'],
      manuscript=p.relative_to(BASE).as_posix(),
      sha256=digest,
      status='MODEL_CROSS_REVIEW_PASS_HUMAN_PENDING' if checked else ('DRAFT_PRESENT_REVIEW_SEPARATE' if p.exists() else 'AUTHORING_PENDING')))
out=['# 단원별 원고\n','모델 교차 검토 통과는 현재 파일의 SHA-256에 대한 한영·한독·교육과정 전편 읽기와 텍스트 과제 풀이 기록을 확인한 경우에만 표시합니다. 사람 감수·실제 청취·학습자 검증은 별도입니다. [전체 판정과 근거](reviews/full-cross-review-20261115/REVIEW_MATRIX.md)를 함께 읽어 주세요.\n',
 '| 구간 | 단원 | 학습 제목 | 이야기 장면 | 집필 상태 |','|---|---|---|---|---|']
for r in rows:
    label=f"[{r['unitId']}]({r['manuscript']})" if r['sha256'] else r['unitId']
    status='모델 3역할 검토 통과 · 사람 감수 대기' if r['status']=='MODEL_CROSS_REVIEW_PASS_HUMAN_PENDING' else ('초고 있음 · 검토 기록 별도' if r['sha256'] else '집필 대기')
    out.append(f"| {r['band']} | {label} | {r['title']} | {r['storyTitle']} | {status} |")
atomic_write(BASE/'INDEX.md','\n'.join(out)+'\n')
atomic_write(BASE/'MANUSCRIPT_INDEX.json',json.dumps(dict(appMutationAllowed=False,synthesisAllowed=False,units=rows),ensure_ascii=False,indent=2)+'\n')
print(json.dumps(dict(units=len(rows),drafts=sum(r['sha256'] is not None for r in rows),modelReviewed=sum(r['status']=='MODEL_CROSS_REVIEW_PASS_HUMAN_PENDING' for r in rows),independentApprovalNotInferred=True)))
