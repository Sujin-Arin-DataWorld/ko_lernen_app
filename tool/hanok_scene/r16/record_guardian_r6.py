from pathlib import Path
import hashlib,json
P=Path(__file__).resolve().parent;D=P/'sarang-guardian-r6'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
source=Path('C:/Users/vjinn/.codex/generated_images/도깨비확정/10푸른 불꽃의 도깨비 전사.png')
(D/'provenance.json').write_text(json.dumps(dict(characterSource=str(source),characterSha256=sha(source),artworkSha256=sha(D/'guardian.png'),generator='built-in image_gen',purpose='Dokkaebi guardian story roof ornament',approved=False),ensure_ascii=False,indent=2),encoding='utf-8')
v=json.loads((D/'verification.json').read_text(encoding='utf-8'));assert v['renderComplete']
scope=json.loads((P/'CURRENT_SCOPE.json').read_text(encoding='utf-8'));scope.update(phase='sarang-guardian-stone-review',candidate='sarang-guardian-r6',authorization='User: fix hovering entry stones, improve reference mineral details, add approved Dokkaebi motif to three circled roof ends',latestVisualReview='R6 native full render and stone/guardian detail renders; user review pending')
(P/'CURRENT_SCOPE.json').write_text(json.dumps(scope,ensure_ascii=False,indent=2),encoding='utf-8')
print('R6 provenance and checkpoint recorded')
