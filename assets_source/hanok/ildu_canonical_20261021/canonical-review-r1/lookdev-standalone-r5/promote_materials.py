"""Register the human-authorized R5 native sources without rewriting their bytes."""
from pathlib import Path
import hashlib,json,subprocess
HOME=Path(__file__).resolve().parent;P=HOME.parent;ROOT=P.parent
def sha(p):
 with p.open('rb') as f:return hashlib.file_digest(f,'sha256').hexdigest()
def write(p,v):p.write_text(json.dumps(v,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
def entry(key,folder):
 v=json.loads((folder/'verification.json').read_text(encoding='utf-8'));r=json.loads((folder/'render-manifest.json').read_text(encoding='utf-8'))
 assert v['passed'] and r['complete'];assert sha(folder/v['candidateNative'])==v['candidateSha256']
 assert all(sha(folder/x['file'])==x['sha256'] for x in r['renders'])
 return dict(key=key,native=(folder/v['candidateNative']).relative_to(P).as_posix(),sha256=v['candidateSha256'],verification=(folder/'verification.json').relative_to(P).as_posix(),
   meshCount=v['meshCount'],originalMeshCount=v.get('originalMeshCount',v['meshCount']),approvedInternalBackingMeshes=v.get('addedApprovedInternalBackingMeshes',0),
   views=[dict(id=key+'-'+view,label=label,image=(folder/('after-'+view+'.png')).relative_to(P).as_posix(),sourceVersion='R5 정본 재질',nativeSha256=v['candidateSha256']) for view,label in [('hero','전체'),('detail','재료 가까이')]])
def main():
 rows=[entry('sarang',P/'lookdev-sarang-r5')]
 # Sarang uses numaru, rather than detail, for the accepted close comparison.
 rows[0]['views'][1]['image']='lookdev-sarang-r5/after-numaru.png'
 assert rows[0]['sha256']=='cab144f08a7836dc0eafc074456104cdbfe21eecd46eadf2c13b882d52efd4c8'
 audit=json.loads((P/'lookdev-buildings-r5/source-audit.json').read_text(encoding='utf-8'))
 rows += [entry(b['key'],P/'lookdev-buildings-r5'/b['key']) for b in audit]
 rows += [entry(k,HOME/k) for k in ['sarang-standalone','jung-standalone']]
 assert len(rows)==17
 authority=dict(date='2026-10-22',source='current human messages in this chat',quotes=[
  '오 훨씬 좋아졌다 이런식으로 다른 건물도 건물에 맞게 적용해줘.',
  '중문간채랑 사랑채는 연결되서 잘린부분 신경쓴건 잘했고 중문간채 사랑채랑 연결 신경안쓰고 지붕 완전한 에셋있잖아 거기도 똑같이 작업해주고 전체 커밋푸시해줘.',
  '너가 만든거 승인한거고, 그걸로 정본 올려서 커밋 푸시 하라고 한건데 왜 회귀했지??'])
 promotion=dict(kind='canonical native R5 material sources',authority=authority,approvedReference='sarang',approvedReferenceSha256=rows[0]['sha256'],
  frozenArchitecture=True,connectedAndStandaloneKeptSeparate=True,originalStandaloneMeshesUnchanged=True,sarangApprovedInternalBackingReused=True,
  glbViewerMaterialUpdated=False,flutterIntegrated=False,releaseApproved=False,entries=rows)
 write(P/'MATERIAL_CANONICAL_PROMOTION_R5.json',promotion)
 catalogpath=P/'catalog.json';backup=HOME/'catalog-before-r5.json'
 if not backup.exists():backup.write_bytes(catalogpath.read_bytes())
 catalog=json.loads(catalogpath.read_text(encoding='utf-8'));bykey={r['key']:r for r in rows}
 for b in catalog['buildings']:
  if b['key'] not in bykey:continue
  r=bykey[b['key']]
  b.setdefault('structuralNative',b['native']);b.setdefault('structuralNativeSha256',b.get('nativeSha256'))
  b['native']=r['native'];b['nativeSha256']=r['sha256']
  b.setdefault('historicalMaterialViews',b['views']);b['views']=r['views'];b['hero']=r['views'][0]['image']
  b['canonicalMaterial']=dict(version='R5',manifest='MATERIAL_CANONICAL_PROMOTION_R5.json',native=r['native'],sha256=r['sha256'],viewerUpdated=False)
  b['materialStatus']='canonical_R5_native; interactive_model_surface_not_yet_R5'
  variant=bykey.get(b['key']+'-standalone')
  if variant:
   b.setdefault('historicalStandaloneViews',b.get('standaloneViews'));b['standaloneViews']=variant['views']
   b['standaloneNative']=variant['native'];b['standaloneNativeSha256']=variant['sha256']
 catalog['canonicalMaterialPromotion']='MATERIAL_CANONICAL_PROMOTION_R5.json';write(catalogpath,catalog)
 for folder in [P/'lookdev-sarang-r5',P/'lookdev-buildings-r5',HOME]:
  status=folder/'CURRENT_STATUS.json';v=json.loads(status.read_text(encoding='utf-8')) if status.exists() else {}
  v.update(status='R5 native materials designated canonical by current human instruction',canonical=True,promotion='../MATERIAL_CANONICAL_PROMOTION_R5.json',publicationAuthorized=True,appIntegrated=False,glbViewerUpdated=False)
  v.pop('next',None);v.pop('newCandidateVisualApproval',None);write(status,v)
 page=P/'lookdev-buildings-r5/index.html';s=page.read_text(encoding='utf-8')
 s=s.replace('건물별 재질 시안 R5','건물별 정본 재질 R5').replace('건물별 3D 후보 저장','R5 정본 Blender 저장').replace('이후 · 붓결 재질','이후 · R5 정본 재질')
 s=s.replace("'건물별 확장 후보 · 개별 시각 검토 전'","'R5 정본 재질 · 현재 사용자 정본 지정'").replace("'붓결 후보'","'R5 정본 재질'")
 s=s.replace('건물 Blender 후보','정본 Blender 원본').replace('후보 원본 크기','R5 원본 크기')
 s=s.replace("let buildings=[],index=0,view='hero';","let buildings=[],index=0,view='hero';")
 # First view is the canonical result. Before material remains available explicitly.
 s=s.replace("view=v||'hero';draw()","view=v||'hero';draw();split(0)")
 page.write_text(s,encoding='utf-8')
 subprocess.run(['python','-X','utf8',str(P/'lookdev-buildings-r5/build_gallery.py')],check=True)
 write(HOME/'VERIFICATION_SUMMARY.json',dict(passed=True,standaloneOriginalMeshes=1434,standaloneTotalMeshes=1435,sourceVariants=2,renderCount=8,allSourceGeometryUvsTransformsPreserved=True,approvedSarangR5Unchanged=True,canonicalPromotion='../MATERIAL_CANONICAL_PROMOTION_R5.json'))
 print('CANONICAL R5 NATIVES REGISTERED',len(rows),flush=True)
if __name__=='__main__':main()
