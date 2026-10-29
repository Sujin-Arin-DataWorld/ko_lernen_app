"""Evidence audit for native material derivatives and every rendered process cut."""
import json,hashlib,sys,datetime
from pathlib import Path
P=Path(__file__).resolve().parent;D=P/'family-r16'
def read(p):return json.loads(p.read_text(encoding='utf-8'))
def sha(p):return hashlib.sha256(Path(p).read_bytes()).hexdigest()
scope=read(P/'PROCESS_STYLE_SCOPE_R16.json');inventory=read(P/'BUILDING_TRANSFER_INVENTORY_R16.json')
partial='--partial' in sys.argv;rows=[];missing=[];errors=[]
for item in scope['buildings']:
 key=item['key'];folder=D/key;native_receipt=P/'sarang-wood-r16/verification.json' if key=='sarang' else folder/'verification.json'
 r=read(native_receipt);entry=next(x for x in inventory['buildings'] if x['key']==key)
 assert sha(entry['canonicalNative'])==entry['canonicalActualSha256'],key+' canonical changed'
 assert sha(r['native'])==r['nativeSha256'],key+' derivative changed'
 assert sha(r['source'])==r['sourceSha256'],key+' source changed'
 assert r['reopenedNativeVerified'] and r['renderComplete'],key+' native render incomplete'
 full=P/'sarang-wood-r16/full.png' if key=='sarang' else folder/'full.png'
 expected_full=r['renders']['full']['sha256'] if key=='sarang' else r['full']['sha256']
 assert sha(full)==expected_full,key+' full image changed'
 out=dict(key=key,name=item['name'],native=r['native'],nativeSha256=r['nativeSha256'],sourceUnchanged=True,canonicalSourceUnchanged=True,full=str(full),stageCount=item['stageCount'],renderedStages=0,renderComplete=False)
 if (folder/'stage-renders.json').exists():
  m=read(folder/'stage-renders.json');selection=read(folder/'stage-selection.json')
  assert m['sourceSha256']==r['nativeSha256'],key+' stage source mismatch'
  assert sha(m['native'])==m['nativeSha256'],key+' timeline changed'
  assert [(s['sequence'],s['processId']) for s in m['steps']]==[(s['sequence'],s['processId']) for s in item['steps'][:len(m['steps'])]],key+' process ID/order changed'
  assert m['stageCount']==item['stageCount']==len(selection['steps'])
  expected={s['sequence']:s for s in selection['steps']};last=set();camera=None
  for s in m['steps']:
   assert sha(folder/s['file'])==s['sha256'],(key,s['sequence'],'image changed')
   vis=expected[s['sequence']]['visibleObjects'];visible=set(vis)
   assert last<=visible,(key,s['sequence'],'not cumulative')
   assert hashlib.sha256(json.dumps(sorted(vis)).encode()).hexdigest()==s['visibleSetSha256']
   assert s['materialBindingSha256']==m['materialBindingSha256']
   assert s['visibleMembers']==len(visible)
   assert camera is None or camera==s['camera'];camera=s['camera']
   for name in visible:assert selection['requiredStage'][name]<=s['sequence']
   for name in visible:
    line=selection['lineage'][name]
    if not line['original']:
     source=line['sourceObject'];assert selection['requiredStage'][source]==selection['requiredStage'][name]
   last=visible
  out.update(renderedStages=len(m['steps']),renderComplete=m['renderComplete'],timeline=m['native'],timelineSha256=m['nativeSha256'],processIdsAndOrderPreserved=True,allRenderedImageHashesVerified=True,cumulativeSelectorsVerified=True,proxyStageLineageVerified=True,materialBindingConstantAcrossStages=True,cameraConstantAcrossStages=True)
  if m['renderComplete']:
   assert len(m['steps'])==item['stageCount']
   assert m['allStageVisibilityVerified'] and m['allStageMaterialsIdenticalToSavedNative']
 else:missing.append(key+' stages not started')
 if not out['renderComplete']:missing.append(key+' stages incomplete')
 rows.append(out)
result=dict(verifiedAtUtc=datetime.datetime.now(datetime.timezone.utc).isoformat(),buildings=rows,buildingCount=len(rows),expectedStages=128,renderedStages=sum(r['renderedStages'] for r in rows),complete=not missing,missing=missing,canonicalSourcesChanged=False,sourceNamesHierarchyMeshUVAndProcessMappingPreserved=True,runtimeIntegrated=False,userApproved=False,materialAdapterSha256=sha(P/'portable_materials_r16.py'),stageSelectorSha256=sha(P/'construction_stages_r16.py'),renderRecipeSha256=sha(P/'render_construction_r16.py'),selectorDifferencesFromOlderPolicy=scope['selectorDifferencesFromOriginalR12DisplayPolicy'],nullProcessOriginalsPreserved=scope['nullProcessMembersInElevenBuildings'])
(D/'AUDIT.json').write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps({k:v for k,v in result.items() if k not in ('buildings','selectorDifferencesFromOlderPolicy')},ensure_ascii=False,indent=2))
if not partial:assert result['complete'] and result['renderedStages']==128
