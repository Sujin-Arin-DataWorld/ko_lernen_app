"""Update common reader guidance; review outcomes remain linked evidence."""
from pathlib import Path
B=Path(__file__).resolve().parents[2]
def rep(s,a,z):
 assert s.count(a)==1,(a[:80],s.count(a))
 return s.replace(a,z)
def save(p,s):
 t=p.with_suffix('.md.tmp');t.write_text(s,encoding='utf-8',newline='');assert t.read_text(encoding='utf-8')==s;t.replace(p);print(p.name)
p=B/'READER_INTRODUCTION.md';s=p.read_text(encoding='utf-8')
s=rep(s,'시범을 따라 해 본 뒤 다른 자료로 혼자 확인하고, 마지막에는 배운 말을 써서 장면을 이어 갑니다.','시범을 따라 해 보고 새 자료로 연습합니다. 독립 확인으로 표시된 과제는 모든 언어의 모범답과 해설을 가린 뒤 문제와 자료만 보고 풀어 봅니다. 그 문제의 답이나 도움을 보고 푼 시도는 지원 연습으로 남깁니다. 마지막에는 배운 말을 써서 장면을 이어 갑니다.')
s=rep(s,'Explore the situation, meet the words and examples, and try a model with help. Then use different materials to check what you can do on your own. Finally, use what you have learned to continue the scene.','Explore the situation, meet the words and examples, and try the model with support. Then practise with new material. For tasks marked as independent checks, hide model answers and explanations in every language and work from the prompt and materials alone. If you consult that task’s answers or help, record the attempt as supported practice. Finally, use what you have learned to continue the scene.')
s=rep(s,'Danach prüfst du an anderen Materialien, was dir selbstständig gelingt. Zum Schluss führst du die Szene mit dem Gelernten weiter.','Danach übst du mit neuem Material. Bei ausdrücklich als selbstständige Überprüfung gekennzeichneten Aufgaben deckst du Musterantworten und Erklärungen in allen Sprachen ab und arbeitest nur mit Aufgabe und Material. Wenn du für diese Aufgabe die Antworten oder Hilfe verwendest, gilt der Versuch als unterstützte Übung. Zum Schluss führst du die Szene mit dem Gelernten weiter.')
s=rep(s,'Wendungen, die du im Haus brauchst, verwendest du auch bei einer Verabredung, wenn du jemandem etwas gibst oder von jemandem etwas bekommst oder im Gespräch mit Freunden.','Wendungen, die du im Haus brauchst, verwendest du auch bei einer Verabredung, beim Tauschen von Gegenständen oder im Gespräch mit Freunden.')
s=rep(s,'편집 메모: 독자용 서문 초고. 한국어·영어·독일어의 독립 교차 검토 전이며, 단원별 원고의 완료 상태와 별개다. 새 정본 사건을 추가하지 않는다.','편집 메모: 독자용 서문. 현재 파일의 교차 검토 판정은 [전체 검토 기록](reviews/full-cross-review-20261115/RESULT.md)에서 확인한다. 단원별 판정·사람 감수·실제 청취와는 별개이며 새 정본 사건을 추가하지 않는다.')
save(p,s)
p=B/'CURRICULUM_REUSE_NOTES.md';s=p.read_text(encoding='utf-8')
s=rep(s,'진행·반복·완료의 네 축 중 진행을 사실 보고에서 분리한다.','진행·반복·완료·결과 상태를 구별할 때 진행을 사실 보고에서 분리한다.')
save(p,s)
p=B/'README.md';s=p.read_text(encoding='utf-8')
s=rep(s,'- [집필 기준](AUTHORING_BRIEF.md)','- [100단원 전체 검토·교정 결과](reviews/full-cross-review-20261115/RESULT.md) · [단원별 최종 파일과 검토 근거](reviews/full-cross-review-20261115/REVIEW_MATRIX.md)\n- [집필 기준](AUTHORING_BRIEF.md)')
s=rep(s,'나머지 원고에는 일부 언어 검토와 사람 감수, 학습자 난이도 검증이 남아 있습니다.','당시 나머지 원고에는 일부 언어 검토와 사람 감수, 학습자 난이도 검증이 남아 있었습니다.')
anchor='지원 자료와 실제 과제를 통해 수용·산출·상호작용·중개를 연결한다는 설계 원칙은'
s=rep(s,anchor,'이후 진행한 100단원 전수 검토의 현재 판정은 위의 전체 검토 결과와 단원별 행렬을 기준으로 확인합니다. 원고 끝의 집필자 메모와 이전 검토 문서는 각 작성 시점의 기록입니다. 최신 판정은 현재 파일의 SHA-256과 연결된 한영·한독·교육과정 검토 기록을 따릅니다. 모델의 텍스트 검토는 사람 감수, 실제 청취, 학습자 난이도·회상 검증을 대신하지 않습니다.\n\n'+anchor)
save(p,s)
