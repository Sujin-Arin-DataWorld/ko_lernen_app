"""Register image evidence without altering the supplied image bytes."""
from pathlib import Path
import hashlib,json,shutil
ROOT=Path(__file__).resolve().parents[2]
REF=ROOT/'assets_unused/pending_review/hwalju-blueprint-review/northern-court/references'
source=Path('C:/Users/vjinn/Pictures/Screenshots')
items=[
 ('sadang','사당','스크린샷 2026-08-29 221750.png','front-dancheong','세 쌍의 창호, 겹처마 단청, 붉은 앞기둥, 마루 아래 환기구'),
 ('sadangmun','사당','스크린샷 2026-08-29 221808.png','gate','녹색 보와 서까래, 태극 판문, 돌 문턱과 계단'),
 ('sadang','사당','스크린샷 2026-08-24 144622.png','oblique','원기둥과 공포, 낮은 기단, 물러난 창호면'),
 ('sadang','사당','스크린샷 2026-08-29 221517.png','porch','툇마루 깊이, 단청, 낮은 돌 디딤판'),
 ('anchae','안채','안채.jpg','front','낮고 긴 처마, 열린 두 칸 대청, 부엌과 방의 구분'),
 ('anchae','안채','스크린샷 2026-08-24 115123.png','daechong','앞이 열린 대청과 뒤 판문, 굽은 보, 툇마루 끝 낮은 난간'),
 ('anchae','안채','스크린샷 2026-08-24 115401.png','sireong','처마 아래 시렁, 창호 살대, 분리된 디딤돌'),
 ('anchae','안채','스크린샷 2026-08-29 161645.png','jar-yard','안채 뒤쪽의 좁은 장독 마당과 담장')]
photos=[]
for ident,folder,name,label,features in items:
    src=source/folder/name;dst=REF/'photos'/f'{ident}-{label}{src.suffix}'
    dst.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(src,dst)
    digest=hashlib.sha256(src.read_bytes()).hexdigest();assert hashlib.sha256(dst.read_bytes()).hexdigest()==digest
    photos.append({'building':ident,'source':str(src),'file':str(dst.relative_to(REF)).replace('\\','/'),'sha256':digest,'features':features,'role':'user-photograph','geometryAuthority':'Details corroborate drawings; photograph-only dimensions remain estimates.'})
record={'photos':photos,'webSources':[
 {'title':'국가유산청 · 일두고택 원형기록','url':'https://digital.khs.go.kr/heri/heriDetail.do?ctptNo=1483801860000&ctptUid=13898859686647401778','role':'official-record-index'},
 {'title':'국가유산청 · 2021년 정기조사 실사','url':'https://digital.khs.go.kr/buis/buisDetail.do?bizUid=13898748261851900019&ctptNo=1483801860000&ctptUid=13898859686647401778&nation=&stakeholdersSes=','role':'official-photograph-index'},
 {'title':'큰누리 · 일두고택 직접 촬영 답사','url':'https://hhl6103.tistory.com/1990?category=1078884','role':'eyewitness-photographs','visuallyInspected':['안곳간과 아래채 안마당 사진','안채 툇마루와 시렁 사진','사당문과 안채 쪽 문 연결 사진'],'features':'Open front porch, suspended shelf, three-bay Arae facing courtyard, paired shrine gate and inner court gate; dates may differ from measured drawings.'}],
 'naming':{'gokgan':'곳간채 (광채)','angotgan':'안곳간채','authority':'User correction 2026-09-28; distinct buildings'},
 'authorityOrder':['Building identity checked against site and user corrections','Measured drawing axes/openings/sections','Canonical illustration and its eight views for visual style','Multiple real photographs for interpretation and craft'],
 'fullPhotoOrSurveyAccuracyClaimed':False}
(REF/'photo-manifest.json').write_text(json.dumps(record,ensure_ascii=False,indent=2),encoding='utf8')
print('Registered',len(photos),'unaltered supplied photographs and',len(record['webSources']),'web sources')
