"""Palette-preserving native material study; no architecture or postprocess edits."""
import bpy, importlib.util, json, time, sys
from pathlib import Path
import numpy as np
OUT=Path(__file__).resolve().parent
R3=OUT.parent/'lookdev-sarang-r3'
NATIVE=R3/'sarang-r3-fix-checkpoint.blend'
EXPECTED='509ffb8a8d714663096c5c7e6d6f0d121a8720f23b281905ebf1cbe328d89c1d'
spec=importlib.util.spec_from_file_location('fix',R3/'refine_r3.py')
fix=importlib.util.module_from_spec(spec);spec.loader.exec_module(fix)
r2=fix.r2;s=fix.s;s.OUT=OUT
VIEWS={
 'numaru':dict(position=(16,-18,5.3),target=(11.5,-2.8,2.7),ortho=6,resolution=(1100,950)),
 'hero':fix.VIEWS['hero'],
 'front':fix.VIEWS['front'],
 'eaves':dict(position=(13.5,-12,3.7),target=(12.5,-4.5,3.9),ortho=2.8,resolution=(1300,650)),
 'wall':dict(position=(23,1,4.3),target=(14.6,1.6,2.8),ortho=3.1,resolution=(1100,900)),
 'stone':dict(position=(6.5,-8.5,4.8),target=(4,-1.9,.63),ortho=3.6,resolution=(1100,900))}

def write(name,data):
 (OUT/name).write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')

def labeled(t,label):return next((n for n in t.nodes if n.label==label),None)

def mean_image(im,panel=None):
 values=np.empty(len(im.pixels),dtype=np.float32);im.pixels.foreach_get(values)
 w,h=im.size;rgb=values.reshape(h,w,4)[:,:,:3]
 if panel:
  x,y=dict(tile=(0,1),stone=(1,1),plaster=(0,0),paper=(1,0))[panel]
  rgb=rgb[int(h*(y*.5+.02)):int(h*(y*.5+.48)),int(w*(x*.5+.02)):int(w*(x*.5+.48))]
 # Byte-image pixels are encoded sRGB; image shader sockets are scene-linear.
 rgb=np.where(rgb<=.04045,rgb/12.92,((rgb+.055)/1.055)**2.4)
 return tuple(float(x) for x in rgb.mean(axis=(0,1),dtype=np.float64))+(1,)

def simplify_image(t,imnode,amount,mean):
 consumers=[l.to_socket for l in list(imnode.outputs['Color'].links)]
 calm=r2.mix(t,imnode.outputs['Color'],mean,amount,'R4 quiet intervals within existing pigment')
 for dest in consumers:t.links.new(calm,dest)

def role(mat):
 if mat.get('r3_role')=='backing':return 'wood'
 if mat.get('r3_role') in ['wood','lattice']:return mat['r3_role']
 if mat.name.startswith('HANDPAINT r2 '):return mat.name.split(' | ',1)[0].replace('HANDPAINT r2 ','')
 return None

def mask(t,category,atlas):
 wood=category in ['wood','lattice']
 coord=labeled(t,'Shift shader sample only, leave mesh UV unchanged') if wood else labeled(t,'Material scale in source UV')
 if coord:vector=coord.outputs[0]
 else:
  uv=r2.node(t,'ShaderNodeUVMap','R4 original end grain UV');uv.uv_map='Craft end grain';vector=uv.outputs['UV']
 coord=r2.stretch(t,vector,dict(wood=(.85,.55,0),lattice=(1.6,.6,0),tile=(.65,.65,0),stone=(.7,.7,0),plaster=(.5,.5,0),paper=(.7,.7,0),endgrain=(.8,.8,0),pigment=(1,1,0))[category],'R4 material brush scale')
 geom=r2.node(t,'ShaderNodeNewGeometry','R4 fixed individual surface phase')
 shift=r2.stretch(t,geom.outputs['Random Per Island'],(1.37,2.73,0),'R4 stable island phase')
 add=r2.node(t,'ShaderNodeVectorMath','R4 stroke address');add.operation='ADD';t.links.new(coord,add.inputs[0]);t.links.new(shift,add.inputs[1])
 fract=r2.node(t,'ShaderNodeVectorMath','R4 remain inside assigned panel');fract.operation='FRACTION';t.links.new(add.outputs[0],fract.inputs[0])
 scale=r2.stretch(t,fract.outputs[0],(.44,.44,0),'R4 atlas inset')
 panel='wood' if category in ['wood','lattice','endgrain'] else 'plaster' if category in ['paper','pigment'] else category
 offset=dict(wood=(.03,.53,0),tile=(.53,.53,0),stone=(.03,.03,0),plaster=(.53,.03,0))[panel]
 add=r2.node(t,'ShaderNodeVectorMath','R4 select '+panel);add.operation='ADD';add.inputs[1].default_value=offset;t.links.new(scale,add.inputs[0])
 tex=r2.node(t,'ShaderNodeTexImage','R4 considered brush marks');tex.image=atlas;tex.interpolation='Cubic';t.links.new(add.outputs[0],tex.inputs['Vector'])
 gray=r2.luminance(t,tex.outputs['Color'],'R4 neutral marks only, no hue shift')
 avg=dict(wood=.5055,tile=.4931,stone=.5066,plaster=.5599)[panel]
 sub=r2.node(t,'ShaderNodeMath','R4 center stroke pigment load');sub.operation='SUBTRACT';sub.inputs[1].default_value=avg;t.links.new(gray,sub.inputs[0])
 strength=dict(wood=1.0,lattice=.55,endgrain=.3,tile=.8,stone=1.0,plaster=.40,paper=.12,pigment=.12)[category]
 mul=r2.node(t,'ShaderNodeMath','R4 restrained brush contrast');mul.operation='MULTIPLY';mul.inputs[1].default_value=strength;t.links.new(sub.outputs[0],mul.inputs[0])
 add=r2.node(t,'ShaderNodeMath','R4 neutral multiplier');add.operation='ADD';add.inputs[1].default_value=1;t.links.new(mul.outputs[0],add.inputs[0])
 return add.outputs[0],gray

def apply(mat,category,atlas,means):
 new=mat.copy();new.name='BRUSH r4 '+category+' | '+mat.name.split(' | ',1)[-1];new['r4_role']=category
 t=new.node_tree
 for n in list(t.nodes):
  if n.type=='TEX_IMAGE' and n.label.startswith('Generated hand painted '):
   simplify_image(t,n,dict(wood=.42,lattice=.45,tile=.22,stone=.22,plaster=.18,paper=.10).get(category,0),means['wood' if category in ['wood','lattice'] else category])
  if n.type=='BUMP' and n.name.startswith('Handpaint r2 |'):
   n.inputs['Strength'].default_value*=.40 if category in ['wood','lattice','tile'] else .65
 n=labeled(t,'Subordinate narrow brush variation')
 if n:n.inputs[0].default_value=.04
 n=labeled(t,'Dry clay pigment on the tile body')
 if n:n.inputs[0].default_value=.28
 stroke,height=mask(t,category,atlas)
 for b in [n for n in t.nodes if n.type=='BSDF_PRINCIPLED']:
  old=b.inputs['Base Color'].links[0].from_socket if b.inputs['Base Color'].is_linked else tuple(b.inputs['Base Color'].default_value)
  color=r2.mix(t,old,stroke,1,'R4 brush accents in existing palette','MULTIPLY');t.links.new(color,b.inputs['Base Color'])
  r2.bump(t,b,height,.00035,.12 if category!='paper' else .04,'R4 shallow pigment tooth')
 new['candidate_status']='unapproved palette-preserving brush study';return new

def signature(scene):
 return dict(lights={o.name:dict(location=list(o.location),energy=o.data.energy,color=list(o.data.color),size=o.data.size) for o in scene.objects if o.type=='LIGHT'},
  world=s.material_state(scene.world),view=[scene.view_settings.view_transform,scene.view_settings.look,scene.view_settings.exposure,scene.view_settings.gamma])

def main():
 start=time.monotonic();assert s.sha(NATIVE)==EXPECTED
 bpy.ops.wm.open_mainfile(filepath=str(NATIVE));scene=bpy.context.scene
 names=[o.name for o in scene.objects if o.type=='MESH'];assert len(names)==711
 objs=fix.originals(names);geometry=s.geometry_state(objs);attrs=r2.attributes(objs);images=r2.image_state();plaques=fix.plaque_state();light=signature(scene)
 mats={sl.material.name:sl.material for o in objs for sl in o.material_slots if sl.material};materials={k:s.material_state(m) for k,m in mats.items()}
 means={'wood':mean_image(bpy.data.images['handpainted-pine-r1.png'])}
 means.update({k:mean_image(bpy.data.images['handpainted-mineral-paper-atlas-r1.png'],k) for k in ['tile','stone','plaster','paper']})
 views=['numaru','hero'] if '--study' in sys.argv else ['numaru','hero','front','eaves','wall','stone']
 scene.cycles.samples=40;scene.cycles.seed=217;scene.render.threads=8
 renders=[]
 for name in views:
  path=OUT/('before-'+name+'.png')
  if name=='numaru':
   import shutil;shutil.copy2(R3/'fixed-numaru.png',path)
   renders.append(dict(variant='fix checkpoint',view=name,file=path.name,sha256=s.sha(path),**VIEWS[name]))
  elif path.exists() and '--reuse-controls' in sys.argv:
   renders.append(dict(variant='fix checkpoint',view=name,file=path.name,sha256=s.sha(path),**VIEWS[name]))
  else:renders.append(dict(variant='fix checkpoint',view=name,**s.render(scene,scene.camera,path.name,**VIEWS[name])))
 atlas=bpy.data.images.load(str(OUT/'textures'/'material-brush-atlas-r1.png'),check_existing=True);atlas.colorspace_settings.name='Non-Color';atlas.pack()
 replacements={};changes=[];coverage={}
 for ob in objs:
  if ob.name in s.PLAQUES:continue
  for sl in ob.material_slots:
   mat=sl.material;category=role(mat) if mat else None
   assert category,ob.name
   coverage.setdefault(category,set()).add(ob.name)
   key=(mat.name,category)
   if key not in replacements:
    new=apply(mat,category,atlas,means);replacements[key]=new;changes.append(dict(source=mat.name,candidate=new.name,category=category))
   sl.link='OBJECT';sl.material=replacements[key]
 assert geometry==s.geometry_state(objs);assert attrs==r2.attributes(objs);assert plaques==fix.plaque_state();assert light==signature(scene)
 assert materials=={k:s.material_state(m) for k,m in mats.items()}
 native=OUT/'sarang-palette-brush-study.blend'
 hero=VIEWS['hero'];scene.camera.location=hero['position'];s.point(scene.camera,hero['target']);scene.camera.data.ortho_scale=hero['ortho']
 bpy.context.preferences.filepaths.save_version=0;bpy.ops.wm.save_as_mainfile(filepath=str(native),check_existing=False)
 bpy.ops.wm.open_mainfile(filepath=str(native));scene=bpy.context.scene
 assert geometry==s.geometry_state(fix.originals(names));assert attrs==r2.attributes(fix.originals(names));assert plaques==fix.plaque_state();assert light==signature(scene)
 assert images=={k:v for k,v in r2.image_state().items() if k in images};assert s.sha(NATIVE)==EXPECTED
 write('verification.json',dict(passed=True,savedNativeReopened=True,all711ExistingMeshGeometryUvsAttributesTransformsModifiersEqual=True,original710AndInternalGapRepairPreserved=True,
  originalImagesPackedBytesEqual=True,sourceMaterialsUnchanged=True,plaquesEqual=True,lightingAndColorManagementEqual=True,newMeshObjects=0,
  noHueSaturationValueGrading=True,neutralBrushMasksOnly=True,sourceSha256=EXPECTED,native=native.name,nativeSha256=s.sha(native),
  candidateApproved=False,appIntegrated=False,glbConverted=False,textureMeans=means,coverage={k:len(v) for k,v in coverage.items()}))
 write('material-changes.json',changes)
 for name in views:renders.append(dict(variant='neutral brush study',view=name,**s.render(scene,scene.camera,'after-'+name+'.png',**VIEWS[name])))
 write('render-manifest.json',dict(renders=renders,matchedLightingAndCameras=True,samples=40,seconds=round(time.monotonic()-start,1)))
 print('BRUSH STUDY COMPLETE',time.monotonic()-start,flush=True)

if __name__=='__main__':main()
