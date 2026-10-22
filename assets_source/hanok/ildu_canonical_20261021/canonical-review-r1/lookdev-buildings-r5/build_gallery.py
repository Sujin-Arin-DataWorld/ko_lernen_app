from pathlib import Path
import json,hashlib
HOME=Path(__file__).resolve().parent
def sha(p):
    with p.open('rb') as f:return hashlib.file_digest(f,'sha256').hexdigest()
NOTES={
 'ansarang':'안사랑채의 기존 목재색을 기준으로 넓은 면과 긴 붓결을 나누고, 촘촘한 창살은 더 낮은 강도로 다듬었습니다.',
 'anchae':'안채의 격자·창호지·회벽을 구분하고, 원본 목재색 안에서 칠의 겹침이 보이게 했습니다.',
 'sadang':'사당의 붉은 칠과 녹색 부재, 단청 문양을 살렸습니다. 채색 부재에는 얇은 붓질만 더했습니다.',
 'jung':'중문간채의 출입 목재와 긴 구조재에 결을 따르는 붓결을, 회벽에는 조용한 칠의 겹침을 적용했습니다.',
 'arae':'아랫채의 목재·회벽·창호를 나누어 손질하고, 기존 재료색과 화덕의 어두운 표현을 보존했습니다.',
 'gokgan':'곳간채의 넓은 판재에는 색면의 강약을 두고, 창살과 쇠장식은 작은 크기에 맞춰 강도를 낮췄습니다.',
 'angotgan':'안채곳간채의 판재·기둥·회벽을 재료별로 나누고, 원본 색을 기준으로 결을 따라 붓질을 더했습니다.',
 'changgo':'창고의 넓은 목재 면에는 긴 붓질을, 돌과 기와에는 더 끊긴 붓질을 사용했습니다.',
 'toilet':'북측 측간의 목재와 흙벽을 분리하고, 과한 장식 없이 각 재료의 질감을 조율했습니다.',
 'toilet1':'남측 측간의 목재·흙벽·기단석을 각각 다르게 처리했습니다. 잘 관리된 소박한 재료감을 목표로 했습니다.',
 'main_gate':'대문의 부재색을 지키며 목재·기와·돌을 다듬었습니다. 현판과 원본 장식의 표현을 보존했습니다.',
 'left_changgo':'새로 만든 왼쪽 협문의 부재와 받침돌을 보존했습니다. 문과 목재의 좌표에 고정된 붓결을 적용했습니다.',
 'right_ansarang':'새로 만든 안채 연결 협문의 목재·기와·계단석을 각각 다듬었습니다. 문을 움직여도 새 붓결이 부재에 붙도록 했습니다.',
 'sadangmun':'사당문의 승인된 붉은 칠·녹색·태극 색을 유지했습니다. 채색 위에 옅은 붓질과 무광 재료 반응을 더했습니다.'}
def main():
    a=json.loads((HOME/'source-audit.json').read_text(encoding='utf-8'));entries=[]
    ref=HOME.parent/'lookdev-sarang-r5';v=json.loads((ref/'verification.json').read_text(encoding='utf-8'))
    entries.append(dict(key='sarang',name='사랑채 · 연결형 · 승인 기준',count=711,native='../lookdev-sarang-r5/'+v['candidateNative'],verification='../lookdev-sarang-r5/verification.json',
      note='사용자가 승인한 사랑채 R5 표현입니다. 다른 건물은 이 붓결의 원리를 각 원본 재료색에 맞춰 적용했습니다.',
      views={k:dict(label=label,before='../lookdev-sarang-r5/before-'+view+'.png',after='../lookdev-sarang-r5/after-'+view+'.png',ratio='4/3' if view=='hero' else '22/19') for k,label,view in [('hero','전체','hero'),('detail','누마루 가까이','numaru')]}))
    for b in a:
        folder=HOME/b['key'];receipt=folder/'verification.json';manifest=folder/'render-manifest.json'
        if not receipt.exists() or not manifest.exists():continue
        v=json.loads(receipt.read_text(encoding='utf-8'));r=json.loads(manifest.read_text(encoding='utf-8'))
        if not r['complete']:continue
        assert v['passed'] and sha(folder/v['candidateNative'])==v['candidateSha256']
        assert all(sha(folder/x['file'])==x['sha256'] for x in r['renders'])
        entries.append(dict(key=b['key'],name=b['name']+(' · 연결형' if b['key']=='jung' else ''),count=b['count'],native=b['key']+'/'+v['candidateNative'],verification=b['key']+'/verification.json',note=NOTES[b['key']],
          views={view:dict(label=label,before=b['key']+'/before-'+view+'.png',after=b['key']+'/after-'+view+'.png',ratio='4/3') for view,label in [('hero','전체'),('detail','재료 가까이')]}))
    for key,name in [('sarang-standalone','사랑채 · 독립형'),('jung-standalone','중문간채 · 독립형')]:
        folder=HOME.parent/'lookdev-standalone-r5'/key
        if not (folder/'verification.json').exists() or not (folder/'render-manifest.json').exists():continue
        v=json.loads((folder/'verification.json').read_text(encoding='utf-8'));r=json.loads((folder/'render-manifest.json').read_text(encoding='utf-8'))
        if not r['complete']:continue
        assert v['passed'] and v['sameReferenceMaterialsTransferred'] and sha(folder/v['candidateNative'])==v['candidateSha256']
        assert all(sha(folder/x['file'])==x['sha256'] for x in r['renders'])
        rel='../lookdev-standalone-r5/'+key+'/'
        entries.append(dict(key=key,name=name,count=v['meshCount'],native=rel+v['candidateNative'],verification=rel+'verification.json',
            note='기존의 온전한 지붕을 가진 독립형입니다. 연결형 R5의 재질을 대응 부재와 지붕 부재에 직접 옮겼습니다.',
            views={view:dict(label=label,before=rel+'before-'+view+'.png',after=rel+'after-'+view+'.png',ratio='22/19' if key=='sarang-standalone' and view=='detail' else '4/3') for view,label in [('hero','전체'),('detail','재료 가까이')]}))
    for entry in entries:
        for view in entry['views'].values():
            for k in ['before','after']:view[k]+='?v='+sha((HOME/view[k]).resolve())[:12]
    promoted=(HOME.parent/'MATERIAL_CANONICAL_PROMOTION_R5.json').exists()
    (HOME/'gallery-data.json').write_text(json.dumps(dict(buildings=entries,complete=len(entries)==17,referenceApproved=True,canonicalMaterialBundle=promoted,promotion='../MATERIAL_CANONICAL_PROMOTION_R5.json'),ensure_ascii=False,indent=2),encoding='utf-8')
    print('Gallery verified entries',len(entries))
if __name__=='__main__':main()
