"""One-time B1.2 corrections after the independent initial reviews."""
from pathlib import Path
B=Path(__file__).resolve().parents[2]/'manuscripts'
edits={
1:[('Ich habe einen Schirm geliehen.','Ich habe mir einen Schirm geliehen.',2),('dass sie einen Schirm geliehen hat.','dass sie sich einen Schirm geliehen hat.',1)],
3:[('학생과 직원은 모두 물건을 하나씩 확인해 주세요','학생과 직원 모두 정해진 절차대로, 한 번에 물건 하나씩 확인해 주세요',1),('Students and staff must all check the items one at a time.','Students and staff should all follow the stated procedure and check one item at a time.',1),('Alle Studierenden und Beschäftigten sollen die Gegenstände einzeln prüfen.','Alle Studierenden und Beschäftigten sollen nach dem angegebenen Verfahren jeweils einen Gegenstand nach dem anderen prüfen.',1)],
4:[('In der Schublade bleibt es trocken, ist aber nicht sofort sichtbar.','Die Schublade ist trocken, aber die Unterlagen sind darin nicht sofort zu sehen.',1)],
6:[('Hyuna hat ihren nach eigener Aussage nicht erhalten; die Rückgabe ist also nicht abgeschlossen.','Hyuna hat ihren nach eigener Aussage nicht erhalten; eine abgeschlossene Rückgabe ist daher nicht belegt.',1)],
}
for n,changes in edits.items():
 p=B/f'B1.2-{n:02}.md'; s=p.read_text(encoding='utf-8')
 for old,new,count in changes:
  assert s.count(old)==count,(p.name,old[:60],s.count(old))
  s=s.replace(old,new)
 t=p.with_suffix('.md.tmp'); t.write_text(s,encoding='utf-8',newline=''); assert t.read_text(encoding='utf-8')==s; t.replace(p); print(p.name)
