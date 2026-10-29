"""Canonical cumulative stage selectors with explicit visual-proxy lineage."""
import json,hashlib
from pathlib import Path
P=Path(__file__).resolve().parent
def stage_sets(sc,key,originalObjects,binding):
 catalog=json.loads((P.parents[2]/'catalog.json').read_text(encoding='utf-8'))
 building=next(b for b in catalog['buildings'] if b['key']==key)
 scope=json.loads((P/'PROCESS_STYLE_SCOPE_R16.json').read_text(encoding='utf-8'))
 contract=next(b for b in scope['buildings'] if b['key']==key)
 assert [(s['id'],s['sequence']) for s in building['steps']]==[(s['processId'],s['sequence']) for s in contract['steps']]
 originals={o.name for o in originalObjects}
 assert set(binding)==originals
 meshes={o.name:o for o in sc.objects if o.type=='MESH' and not o.get('displayOnly') and 'display ground' not in o.name.lower()}
 baseline={name:dict(hideRender=bool(o.hide_render),hideViewport=bool(o.hide_viewport)) for name,o in meshes.items()}
 required={};lineage={}
 def resolve(name,chain=()):
  if name in required:return required[name]
  if name in chain:raise ValueError(('proxy lineage cycle',chain,name))
  if name in binding:
   value=int(binding[name]['reviewStage']);lineage[name]=dict(sourceObject=name,processId=binding[name].get('processId'),original=True)
  else:
   ob=meshes[name];parent=ob.get('construction_parent') or ob.get('source_member')
   if not isinstance(parent,str) or parent not in meshes:raise ValueError(('unmapped stage proxy',name,parent))
   value=resolve(parent,chain+(name,));lineage[name]=dict(sourceObject=lineage[parent]['sourceObject'],processId=lineage[parent]['processId'],constructionParent=parent,original=False)
  required[name]=value;return value
 for name in meshes:resolve(name)
 steps=[];previous=set()
 for step in building['steps']:
  sequence=int(step['sequence']);visible=sorted(name for name in meshes if not baseline[name]['hideRender'] and required[name]<=sequence)
  source_visible=sorted(name for name in visible if name in originals)
  proxies=sorted(name for name in visible if name not in originals)
  steps.append(dict(sequence=sequence,processId=step['id'],label=step['label'],isFinal=step.get('isFinal',False),visibleObjects=visible,visibleOriginals=source_visible,visibleProxies=proxies,newMembers=len(set(visible)-previous),newOriginalMembers=len(set(source_visible)-previous),visibleMembers=len(visible),visibleSetSha256=hashlib.sha256(json.dumps(visible).encode()).hexdigest(),noNewGeometry=set(visible)==previous))
  previous=set(visible)
 return dict(key=key,buildingId=building['buildingId'],name=building['name'],selectorAuthority='canonical-review catalog and preserved GLB/native explicit reviewStage',canonicalCatalogSha256=hashlib.sha256((P.parents[2]/'catalog.json').read_bytes()).hexdigest(),steps=steps,originalObjectCount=len(originals),proxyObjectCount=len(meshes)-len(originals),baseline=baseline,requiredStage=required,lineage=lineage,nullProcessOriginals=[n for n,r in binding.items() if r.get('processId') is None],legacyDisplayPolicyDifferences=[d for d in scope['selectorDifferencesFromOriginalR12DisplayPolicy'] if d['key']==key],legacyPolicyUnmodified=True,processIdsAndOrderPreserved=True,sourceDataEdited=False)
def set_stage(sc,report,sequence):
 row=next(r for r in report['steps'] if r['sequence']==sequence);visible=set(row['visibleObjects'])
 for name in report['baseline']:sc.objects[name].hide_render=name not in visible
 return row
def restore(sc,report):
 for name,state in report['baseline'].items():
  sc.objects[name].hide_render=state['hideRender'];sc.objects[name].hide_viewport=state['hideViewport']
 import bpy
 bpy.context.view_layer.update()
