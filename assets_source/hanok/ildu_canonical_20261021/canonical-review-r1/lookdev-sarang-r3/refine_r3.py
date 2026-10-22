"""Correct the two reported defects, save a checkpoint, then add a very thin warm glaze."""
import bpy,importlib.util,json,hashlib,shutil,time
from pathlib import Path
from mathutils import Vector
OUT=Path(__file__).resolve().parent
R2=OUT.parent/'lookdev-sarang-r2'
NATIVE=R2/'sarang-handpaint-candidate.blend'
EXPECTED='7f04ba42cc0431ef7789e9ab28c514da4f1f464988779fa30ca3d5c6b40a3e36'
spec=importlib.util.spec_from_file_location('r2',R2/'render_handpainted.py')
r2=importlib.util.module_from_spec(spec);spec.loader.exec_module(r2)
s=r2.source;s.OUT=OUT
BACKING='SurfaceRepair.apron joint backings'
VIEWS={
 'hero':dict(position=(29.4,-30.2,15.45),target=(7.4,1.8,2.85),ortho=22,resolution=(1400,1050)),
 'front':dict(position=(6.4,-22,3.5),target=(6.4,0,3.35),ortho=12.8,resolution=(1400,840)),
 'board':dict(position=(1.35,-12,1.67),target=(1.35,.08,1.67),ortho=3.0,resolution=(1000,650)),
 'numaru':dict(position=(16,-18,5.3),target=(11.5,-2.8,2.7),ortho=6.0,resolution=(1100,950))}

def write(file,data):
 (OUT/file).write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')

def originals(names):return [bpy.data.objects[n] for n in names]

def bounds(objects):
 points=[o.matrix_world@Vector(v) for o in objects for v in o.bound_box]
 return [[min(v[i] for v in points) for i in range(3)],[max(v[i] for v in points) for i in range(3)]]

def ray(x,z):
 hit,loc,normal,face,ob,matrix=bpy.context.scene.ray_cast(bpy.context.evaluated_depsgraph_get(),Vector((x,-15,z)),Vector((0,1,0)))
 return dict(object=ob.name if hit else None,point=list(loc) if hit else None)

def components(ob):
 mesh=ob.data;parents=list(range(len(mesh.vertices)))
 def root(v):
  while parents[v]!=v:parents[v]=parents[parents[v]];v=parents[v]
  return v
 for e in mesh.edges:
  a,b=[root(v) for v in e.vertices];parents[b]=a
 used={v for p in mesh.polygons for v in p.vertices};groups={}
 for v in used:groups.setdefault(root(v),[]).append(ob.matrix_world@mesh.vertices[v].co)
 return [([min(v[i] for v in vs) for i in range(3)],[max(v[i] for v in vs) for i in range(3)]) for vs in groups.values()]

def mix_base(mat,amount,color,label):
 t=mat.node_tree
 for b in [n for n in list(t.nodes) if n.type=='BSDF_PRINCIPLED']:
  base=b.inputs['Base Color'];prior=base.links[0].from_socket if base.is_linked else None
  n=t.nodes.new('ShaderNodeMixRGB');n.name=label;n.label=label
  n.inputs[0].default_value=amount;n.inputs[1].default_value=base.default_value;n.inputs[2].default_value=color
  if prior:t.links.new(prior,n.inputs[1])
  t.links.new(n.outputs[0],base)

def even_materials(objects):
 replacements={};changes=[]
 for ob in objects:
  if ob.name in s.PLAQUES:continue
  for sl in ob.material_slots:
   mat=sl.material
   if not mat:continue
   role='lattice' if mat.name.startswith('HANDPAINT r2 lattice |') else 'wood' if mat.name.startswith('HANDPAINT r2 wood |') else None
   if not role:continue
   if mat.name not in replacements:
    new=mat.copy();new.name='R3 FIX '+role+' | '+mat.name.split(' | ',1)[-1];new['r3_role']=role
    for n in new.node_tree.nodes:
     if n.label=='Individual maintained timber tone':
      for e,value in zip(n.color_ramp.elements,[.95,1.05]):e.color=(value,value,value,1)
    mix_base(new,.14 if role=='wood' else .10,(.29,.155,.073,1),'R3 restrained pigment variation')
    replacements[mat.name]=new;changes.append(dict(source=mat.name,candidate=new.name,role=role,memberToneRange=[.95,1.05],evenGlaze=.14 if role=='wood' else .10,reliefUnchanged=True))
   sl.link='OBJECT';sl.material=replacements[mat.name]
 return changes

def close_apron_seams():
 panels={}
 for ob in bpy.context.scene.objects:
  if not ob.name.startswith('Craft.Sarang broad apron boards'):continue
  for lo,hi in components(ob):
   key=tuple(round(v,4) for v in [lo[0],hi[0],lo[1],hi[1]])
   panels.setdefault(key,[]).append((lo[2],hi[2]))
 verts=[];faces=[];strips=[]
 for (xmin,xmax,ymin,ymax),levels in panels.items():
  levels.sort()
  for lower,upper in zip(levels,levels[1:]):
   gap=upper[0]-lower[1]
   if not .0001<gap<.012:continue
   zmin=lower[1]-.0003;zmax=upper[0]+.0003;y=ymax+.001
   idx=len(verts);verts.extend([(xmin,y,zmin),(xmax,y,zmin),(xmax,y,zmax),(xmin,y,zmax)]);faces.append(tuple(idx+i for i in range(4)))
   strips.append(dict(x=[xmin,xmax],y=y,z=[zmin,zmax],originalGapMetres=gap))
 assert strips,'No matching apron joints found'
 mesh=bpy.data.meshes.new('Internal joint backing faces only');mesh.from_pydata(verts,[],faces);mesh.update()
 ob=bpy.data.objects.new(BACKING,mesh);bpy.context.scene.collection.objects.link(ob)
 uv=mesh.uv_layers.new(name='Gye cared member grain v52')
 for poly in mesh.polygons:
  for li in poly.loop_indices:
   co=mesh.vertices[mesh.loops[li].vertex_index].co;uv.data[li].uv=(co.z*.42+1.1,co.x*.34+2.7)
 mat=bpy.data.objects['Craft.Sarang broad apron boards'].material_slots[0].material.copy()
 mat.name='R3 internal wood joint shadow';mat['r3_role']='backing'
 t=mat.node_tree
 for b in [n for n in list(t.nodes) if n.type=='BSDF_PRINCIPLED']:
  inp=b.inputs['Base Color'];prior=inp.links[0].from_socket
  n=t.nodes.new('ShaderNodeMixRGB');n.blend_type='MULTIPLY';n.inputs[0].default_value=1;n.inputs[2].default_value=(.52,.52,.52,1)
  t.links.new(prior,n.inputs[1]);t.links.new(n.outputs[0],inp)
 mesh.materials.append(mat)
 ob['surfaceRepairOnly']=True;ob['sourceObject']=BACKING;ob['reviewStage']=14;ob['processId']='ildu.sarangchae-maru'
 ob['purpose']='Recessed backing behind existing 6 mm apron board joints; exterior source boards unchanged'
 return ob,strips

def plaque_state():
 return {n:[s.material_state(sl.material) for sl in bpy.data.objects[n].material_slots] for n in s.PLAQUES}

def save_verified(filename,names,geometry,attrs,images,plaques,source_bounds):
 scene=bpy.context.scene;camera=scene.camera;hero=VIEWS['hero']
 camera.location=hero['position'];s.point(camera,hero['target']);camera.data.ortho_scale=hero['ortho']
 scene.render.resolution_x,scene.render.resolution_y=hero['resolution']
 bpy.context.view_layer.update()
 assert s.geometry_state(originals(names))==geometry
 assert r2.attributes(originals(names))==attrs
 assert plaque_state()==plaques
 assert r2.image_state()==images
 assert bounds(originals(names)+[bpy.data.objects[BACKING]])==source_bounds
 bpy.context.preferences.filepaths.save_version=0
 path=OUT/filename;bpy.ops.wm.save_as_mainfile(filepath=str(path),check_existing=False)
 bpy.ops.wm.open_mainfile(filepath=str(path))
 assert s.geometry_state(originals(names))==geometry
 assert r2.attributes(originals(names))==attrs
 assert plaque_state()==plaques
 assert r2.image_state()==images
 assert len([o for o in bpy.context.scene.objects if o.type=='MESH'])==711
 assert bounds(originals(names)+[bpy.data.objects[BACKING]])==source_bounds
 assert s.sha(NATIVE)==EXPECTED
 record=dict(file=filename,sha256=s.sha(path),original710MeshesGeometryUvsTransformsModifiersEqual=True,originalAttributesEqual=True,
  originalImagesPackedBytesEqual=True,originalPlaquesEqual=True,addedInternalSurfaceObjects=1,totalMeshObjects=711,exteriorBoundsEqual=True,reopenedAndVerified=True,sourceR2NativeUnchanged=True)
 print('VERIFIED SAVED',filename,record['sha256'],flush=True)
 return record

def warm_glaze(objects):
 replacements={};changes=[]
 for ob in objects:
  if ob.name in s.PLAQUES:continue
  for slot in ob.material_slots:
   mat=slot.material
   if not mat:continue
   role=mat.get('r3_role')
   if role not in ['wood','lattice'] and not mat.name.startswith('HANDPAINT r2 plaster |'):continue
   if mat.name not in replacements:
    role=role or 'plaster';new=mat.copy();new.name='R3 WARM '+role+' | '+mat.name.split(' | ',1)[-1]
    amount=.025 if role in ['wood','plaster'] else .02
    color=(.34,.185,.085,1) if role!='plaster' else (.78,.67,.49,1)
    mix_base(new,amount,color,'R3 very thin warm handpaint glaze')
    replacements[mat.name]=new;changes.append(dict(source=mat.name,candidate=new.name,role=role,glaze=amount,reliefUnchanged=True))
   slot.link='OBJECT';slot.material=replacements[mat.name]
 return changes

def main():
 start=time.monotonic();assert s.sha(NATIVE)==EXPECTED
 bpy.ops.wm.open_mainfile(filepath=str(NATIVE));scene=bpy.context.scene
 names=[o.name for o in scene.objects if o.type=='MESH'];assert len(names)==710
 objs=originals(names);geometry=s.geometry_state(objs);attrs=r2.attributes(objs);images=r2.image_state();plaques=plaque_state();source_bounds=bounds(objs)
 source_mats={sl.material.name:sl.material for o in objs for sl in o.material_slots if sl.material}
 signatures={n:s.material_state(m) for n,m in source_mats.items()}
 scene.cycles.samples=40;scene.cycles.seed=217;scene.render.threads=8
 renders=[]
 old_manifest=json.loads((R2/'render-manifest.json').read_text(encoding='utf-8'))
 for view in ['hero','front']:
  item=next(x for x in old_manifest['renders'] if x['view']==view and x['variant'].startswith('r2'))
  assert s.sha(R2/item['file'])==item['sha256']
  file='before-'+view+'.png';shutil.copy2(R2/item['file'],OUT/file)
  renders.append(dict(item,variant='R2 baseline',file=file))
 for view in ['board','numaru']:
  renders.append(dict(variant='R2 baseline',view=view,**s.render(scene,scene.camera,'before-'+view+'.png',**VIEWS[view])))
 gap_before=[dict(x=1,z=z,**ray(1,z)) for z in [1.39,1.663]]
 assert all(x['object'] is None for x in gap_before),'White-gap regression not reproduced'
 changes=even_materials(objs);backer,strips=close_apron_seams();bpy.context.view_layer.update()
 gap_after=[dict(x=1,z=z,**ray(1,z)) for z in [1.39,1.663]]
 assert all(x['object']==BACKING for x in gap_after)
 assert signatures=={n:s.material_state(m) for n,m in source_mats.items()},'Original R2 material graphs mutated'
 write('gap-regression.json',dict(before=gap_before,after=gap_after,passed=True,internalStrips=strips,existingExteriorBoardsMoved=False))
 write('fix-material-changes.json',changes)
 fixed=save_verified('sarang-r3-fix-checkpoint.blend',names,geometry,attrs,images,plaques,source_bounds)
 write('phase-status.json',dict(fixCheckpointSavedAndVerified=True,checkpoint=fixed,warmRefinementComplete=False))
 scene=bpy.context.scene
 renders.append(dict(variant='R3 saved fix checkpoint',view='numaru',**s.render(scene,scene.camera,'fixed-numaru.png',**VIEWS['numaru'])))
 warm_changes=warm_glaze(originals(names));write('warm-glaze-changes.json',warm_changes)
 final=save_verified('sarang-r3-warm-refined.blend',names,geometry,attrs,images,plaques,source_bounds)
 write('verification.json',dict(passed=True,checkpoint=fixed,final=final,originalR2Sha256=EXPECTED,glbConverted=False,appIntegrated=False,
  sourceExistingGeometryChanged=False,internalJointBackingAdded=True,lightingUnchanged=True,surfaceReliefUnchanged=True,newTextureImagesGenerated=False,candidateApproved=False))
 write('phase-status.json',dict(fixCheckpointSavedAndVerified=True,checkpoint=fixed,warmRefinementComplete=True,final=final,finalRendersComplete=False))
 scene=bpy.context.scene
 for view,config in VIEWS.items():
  renders.append(dict(variant='R3 final restrained warm glaze',view=view,**s.render(scene,scene.camera,'after-'+view+'.png',**config)))
 write('render-manifest.json',dict(renders=renders,samples=40,lightingUnchanged=True,sourceR2Sha256=EXPECTED,checkpoint=fixed,final=final,seconds=round(time.monotonic()-start,1)))
 write('phase-status.json',dict(fixCheckpointSavedAndVerified=True,checkpoint=fixed,warmRefinementComplete=True,final=final,finalRendersComplete=True))
 print('R3 COMPLETE',time.monotonic()-start,flush=True)

if __name__=='__main__':
 raise SystemExit('WITHDRAWN: no hue warming; use palette-preserving R4 study.')
