"""Transfer finished connected R5 materials to existing full-roof native variants."""
import bpy,json,sys,importlib.util,re,time
from pathlib import Path
HOME=Path(__file__).resolve().parent;PACKAGE=HOME.parent
spec=importlib.util.spec_from_file_location('extension',PACKAGE/'lookdev-buildings-r5/restyle_building.py');e=importlib.util.module_from_spec(spec);spec.loader.exec_module(e)
s=e.s;r2=e.r2
def norm(name):return re.sub(r'\.\d{3}$','',name)
def write(path,value):e.write(path,value)
def main():
 start=time.monotonic();base=sys.argv[sys.argv.index('--')+1];key=base+'-standalone';out=HOME/key;out.mkdir(exist_ok=True);s.OUT=out
 source=next(v for v in json.loads((HOME/'source-audit.json').read_text(encoding='utf-8')) if v['key']==key)
 native=Path(source['native']);assert s.sha(native)==source['sha256']
 if base=='sarang':
  reference=PACKAGE/'lookdev-sarang-r5/sarang-three-value-brush-candidate.blend';expected='cab144f08a7836dc0eafc074456104cdbfe21eecd46eadf2c13b882d52efd4c8'
 else:
  refreceipt=json.loads((PACKAGE/'lookdev-buildings-r5/jung/verification.json').read_text(encoding='utf-8'));reference=PACKAGE/'lookdev-buildings-r5/jung'/refreceipt['candidateNative'];expected=refreceipt['candidateSha256']
 assert s.sha(reference)==expected
 bpy.ops.wm.read_factory_settings(use_empty=True)
 with bpy.data.libraries.load(str(native),link=False) as (src,dst):dst.objects=list(source['names'])
 scene=bpy.context.scene;scene.name=source['name']+' | existing full roof, R5 materials'
 for ob in dst.objects:scene.collection.objects.link(ob)
 bpy.context.view_layer.update();obs=[bpy.data.objects[n] for n in source['names']];assert len(obs)==source['count']
 geometry=s.geometry_state(obs);attrs=r2.attributes(obs);props=e.object_properties(obs);images=r2.image_state()
 originals={sl.material.name:sl.material for o in obs for sl in o.material_slots if sl.material}
 for m in originals.values():m.use_fake_user=True
 matstates={k:s.material_state(m) for k,m in originals.items()}
 views,bounds=e.setup(scene,obs)
 if base=='sarang':
  views['hero']=dict(e.art.VIEWS['hero'],resolution=(1200,900));views['detail']=dict(e.art.VIEWS['numaru'],resolution=(1100,950))
 lighting=e.art.study.signature(scene);renders=[]
 cachefile=out/'controls.json';cache=json.loads(cachefile.read_text(encoding='utf-8')) if cachefile.exists() else {}
 for name,view in views.items():
  prior=next((r for r in cache.get('renders',[]) if r['view']==name),None)
  if cache.get('sourceSha256')==source['sha256'] and cache.get('views',{}).get(name)==json.loads(json.dumps(view)) and prior and s.sha(out/prior['file'])==prior['sha256']:renders.append(prior)
  else:renders.append(dict(view=name,variant='original full-roof native',**s.render(scene,scene.camera,'before-'+name+'.png',**view)))
 write(cachefile,dict(sourceSha256=source['sha256'],views=views,renders=renders))
 with bpy.data.libraries.load(str(reference),link=False) as (src,dst):dst.objects=list(src.objects)
 refs={o.name:o for o in dst.objects if o and o.type=='MESH'}
 role_refs={}
 for o in refs.values():
  if o.get('geometry_role'):role_refs.setdefault(str(o['geometry_role']),o)
 by_material={};direct={};counts={};transfers=[];unmatched=[]
 for o in obs:
  srcname=o.get('standaloneRetainedSource');ref=refs.get(srcname) if srcname else None
  if ref and len(ref.material_slots)==len(o.material_slots):
   direct[o.name]=ref
   for sl,rsl in zip(o.material_slots,ref.material_slots):
    if sl.material and rsl.material and not rsl.material.name.startswith('PAINT R5 selected'):
     by_material.setdefault(norm(sl.material.name),rsl.material)
 for o in obs:
  ref=direct.get(o.name)
  if ref is None:
   role=str(o.get('geometry_role',''));candidate=refs.get(role) or role_refs.get(role)
   if candidate and len(candidate.material_slots)==len(o.material_slots):ref=candidate
  for i,sl in enumerate(o.material_slots):
   old=sl.material
   if not old:continue
   new=ref.material_slots[i].material if ref else by_material.get(norm(old.name))
   if new is None:
    unmatched.append(dict(object=o.name,slot=i,material=old.name));continue
   # Plaques keep their original identity instead of introducing renamed image copies.
   if any(x in (o.name+' '+old.name).lower() for x in ['original plaque','calligraphy','inscription']):
    counts['original plaque preserved']=counts.get('original plaque preserved',0)+1;continue
   useduv={n.uv_map for n in new.node_tree.nodes if n.type=='UVMAP' and n.uv_map}
   available={uv.name for uv in o.data.uv_layers}
   # Missing source UVs must never silently produce a flat texture.
   active=[u for u in useduv if u.startswith('Gye cared member') or u=='Craft end grain']
   assert set(active)<=available,(o.name,new.name,active,available)
   sl.link='OBJECT';sl.material=new
   method='retained member' if o.name in direct else 'source role' if ref else 'same source material'
   counts[method]=counts.get(method,0)+1;transfers.append(dict(object=o.name,slot=i,source=old.name,referenceMaterial=new.name,method=method))
 assert not unmatched,('Unmapped original material slots',unmatched[:15])
 extras=[]
 if base=='sarang':
  # Reuse the exact accepted concealed seam backing; do not edit any of the829
  # original standalone members or invent a roof/architectural replacement.
  backing=refs.get('SurfaceRepair.apron joint backings');assert backing
  scene.collection.objects.link(backing);extras=[backing]
 assert geometry==s.geometry_state(obs);assert attrs==r2.attributes(obs);assert props==e.object_properties(obs)
 assert matstates=={k:s.material_state(m) for k,m in originals.items()}
 bindings={o.name:[sl.material.name if sl.material else None for sl in o.material_slots] for o in obs}
 extra_geometry=s.geometry_state(extras);extra_attrs=r2.attributes(extras)
 path=out/(key+'-r5-brush-candidate.blend');bpy.context.preferences.filepaths.save_version=0
 scene.camera.location=views['hero']['position'];s.point(scene.camera,views['hero']['target']);scene.camera.data.ortho_scale=views['hero']['ortho']
 bpy.ops.wm.save_as_mainfile(filepath=str(path),check_existing=False,compress=True,relative_remap=False)
 bpy.ops.wm.open_mainfile(filepath=str(path));scene=bpy.context.scene;obs=[bpy.data.objects[n] for n in source['names']]
 assert geometry==s.geometry_state(obs);assert attrs==r2.attributes(obs);assert props==e.object_properties(obs)
 assert bindings=={o.name:[sl.material.name if sl.material else None for sl in o.material_slots] for o in obs}
 assert extra_geometry==s.geometry_state([bpy.data.objects[n] for n in extra_geometry]);assert extra_attrs==r2.attributes([bpy.data.objects[n] for n in extra_attrs])
 assert images=={k:v for k,v in r2.image_state().items() if k in images}
 assert matstates=={k:s.material_state(bpy.data.materials[k]) for k in matstates}
 assert lighting==e.art.study.signature(scene);assert s.sha(native)==source['sha256'];assert s.sha(reference)==expected
 record=dict(key=key,name=source['name'],passed=True,reopened=True,originalMeshCount=source['count'],meshCount=len([o for o in scene.objects if o.type=='MESH']),
  geometryUVsTransformsModifiersEqual=True,attributesStagesPropertiesEqual=True,sourceMaterialGraphsEqual=True,sourceImageBytesEqual=True,
  sourceNative=str(native),sourceSha256=source['sha256'],referenceNative=str(reference),referenceSha256=expected,candidateNative=path.name,candidateSha256=s.sha(path),
  sameReferenceMaterialsTransferred=True,transferCounts=counts,transfers=transfers,views=views,bounds=bounds,
  approvedConcealedBackingReused=bool(extras),addedArchitecturalMeshes=0,addedApprovedInternalBackingMeshes=len(extras),newUVsOnOriginalMeshes=0,
  canonicalPromoted=False,glbConverted=False,appIntegrated=False)
 write(out/'verification.json',record)
 for name,view in views.items():
  renders.append(dict(view=name,variant='R5 full-roof candidate',**s.render(scene,scene.camera,'after-'+name+'.png',**view)))
  write(out/'render-manifest.json',dict(complete=len(renders)==4,matchedCameraLights=True,samples=24,renders=renders,seconds=round(time.monotonic()-start,1)))
 print('STANDALONE COMPLETE',key,counts,round(time.monotonic()-start,1),flush=True)
if __name__=='__main__':main()
