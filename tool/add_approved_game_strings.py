from pathlib import Path
import json

root = Path(__file__).resolve().parents[1]
entries = {
 'approvedQuizTitle': ('Wörter-Quiz','Word Quiz'),
 'approvedQuizCorrect': ('{count} richtig','{count} correct'),
 'approvedQuizChooseMeaning': ('Wähle die Bedeutung.','Choose the meaning.'),
 'approvedGameListen': ('Anhören','Listen'),
 'approvedMatchingTitle': ('Paare finden','Find pairs'),
 'approvedMatchingInstruction': ('Erst Koreanisch, dann die Bedeutung.','First Korean, then the meaning.'),
 'approvedMatchingCounter': ('{count} von {total} Paaren','{count} of {total} pairs'),
 'approvedMatchingPickKorean': ('Tippe auf ein koreanisches Wort.','Tap a Korean word.'),
 'approvedMatchingPickMeaning': ('Wähle jetzt die passende Bedeutung.','Now choose the matching meaning.'),
 'approvedMatchingRetry': ('Tippe auf die passende Bedeutung.','Tap the matching meaning.'),
 'approvedMatchingFound': ('Ein Paar gefunden.','Pair found.'),
}
for i,lang in enumerate(['de','en']):
 p=root/f'lib/l10n/app_{lang}.arb'
 s=p.read_text(encoding='utf-8')
 additions={}
 for k,v in entries.items():
  if f'"{k}"' in s: continue
  additions[k]=v[i]
  placeholders={n:{'type':'int'} for n in ['count','total'] if '{'+n+'}' in v[i]}
  if placeholders: additions['@'+k]={'placeholders':placeholders}
 if additions:
  p.write_text(s.rstrip()[:-1].rstrip()+',\n'+json.dumps(additions,ensure_ascii=False,indent=2)[2:-2]+'\n}\n',encoding='utf-8')
